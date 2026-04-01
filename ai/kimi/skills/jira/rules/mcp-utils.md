# MCP Utility Patterns

Reusable patterns for MCP server interaction used by all jira skill rules.

## Section 1: MCP Response Validation (INFRA-02)

Always validate MCP responses before processing to ensure data integrity and prevent downstream failures.

### Validation Requirements

1. **Check `isError` flag first** - All MCP responses include this field
2. **Validate critical fields** - After `isError` check, verify required fields are present and non-empty
3. **For Jira responses:** Require `key` and `fields.summary` at minimum
4. **For Confluence responses:** Require `id` and `body` at minimum

### Validation Pattern

Use Python 3 for JSON validation:

```bash
python3 -c "
import json, sys
data = json.load(sys.stdin)
if data.get('isError', False):
    print('MCP_ERROR: ' + str(data.get('error', 'unknown')), file=sys.stderr)
    sys.exit(1)
sys.exit(0)
" <<< "$response"
```

### Field Validation

Check each required field individually and report which specific field is missing:

```bash
validate_jira_response() {
    local response="$1"

    # Check isError flag
    python3 -c "import json,sys; data=json.load(sys.stdin); sys.exit(0 if not data.get('isError') else 1)" <<< "$response" || return 1

    # Check critical fields present and non-empty
    python3 -c "
import json, sys
data = json.load(sys.stdin)
required = ['key', 'fields']
if not all(field in data for field in required):
    print('ERROR: Missing required fields', file=sys.stderr)
    sys.exit(1)
if not data['fields'].get('summary'):
    print('ERROR: Missing summary field', file=sys.stderr)
    sys.exit(1)
sys.exit(0)
" <<< "$response"
}
```

## Section 2: Retry Logic (INFRA-03)

Retry MCP calls with exponential backoff to handle transient failures gracefully.

### Retry Parameters (per D-03)

- **Jira/Confluence (mcp-atlassian):** Retry 3 times with 30-second waits doubling each attempt (30s, 60s, 120s)
- **Figma:** 1 retry only with 30-second wait
- **On final failure:** Log the specific reason the service could not be reached
- **Partial context resilience:** If one MCP server fails, continue fetching from others. Mark failed sources in state file.

### Retry Wrapper Function

```bash
retry_with_backoff() {
    local max_attempts="$1"
    local delay=30
    shift
    local cmd="$@"

    for attempt in $(seq 1 "$max_attempts"); do
        echo "Attempt $attempt/$max_attempts" >&2
        if eval "$cmd"; then
            return 0
        fi
        if [ "$attempt" -lt "$max_attempts" ]; then
            echo "Retrying in ${delay}s..." >&2
            sleep "$delay"
            delay=$((delay * 2))
        fi
    done
    echo "ERROR: All $max_attempts retry attempts failed" >&2
    return 1
}
```

### Service-Specific Retry Counts

```bash
# For Jira/Confluence MCP calls
retry_with_backoff 3 "mcp__mcp-atlassian__jira_get_issue issue_key=$TICKET_ID"

# For Figma MCP calls (max_attempts=1 means no retries, just the initial call)
retry_with_backoff 1 "mcp__figma__get_file file_key=$FILE_KEY"
```

### Partial Context Handling

Continue fetching from other sources when one MCP server fails:

```bash
# Fetch Jira (critical - must succeed)
fetch_jira_with_retry "$TICKET_ID" || {
    echo "ERROR: Jira fetch failed after 3 retries - cannot proceed" >&2
    exit 1
}

# Fetch Confluence (best effort)
fetch_confluence_links "$TICKET_ID" || {
    echo "WARNING: Confluence unavailable, continuing without context pages"
    mark_source_failed "confluence" "MCP timeout after 3 retries"
}

# Fetch Figma (best effort)
fetch_figma_links "$TICKET_ID" || {
    echo "WARNING: Figma unavailable, continuing without design context"
    mark_source_failed "figma" "MCP timeout after 1 retry"
}
```

## Section 3: Credential Extraction (INFRA-04)

Read credentials from `~/.claude/mcp.json` to avoid hardcoding secrets in skill files.

### Security Requirements

- **NEVER hardcode credentials** in skill files, rule files, or command output
- **NEVER expose credentials** in error messages or logs
- **ALWAYS read from MCP config** at `~/.claude/mcp.json`

### Jira Credential Extraction

```bash
JIRA_CREDS=$(python3 -c "
import json
with open('$HOME/.claude/mcp.json') as f:
    config = json.load(f)
    env = config['mcpServers']['mcp-atlassian']['env']
    print(env['JIRA_USERNAME'])
    print(env['JIRA_API_TOKEN'])
")
JIRA_USERNAME=$(echo "$JIRA_CREDS" | head -1)
JIRA_API_TOKEN=$(echo "$JIRA_CREDS" | tail -1)
```

### Secure Usage in curl Commands

Always use variables for credentials, and prefix sensitive commands with a leading space to prevent shell history exposure:

```bash
# Leading space before curl to prevent history exposure
 curl -s -L -u "$JIRA_USERNAME:$JIRA_API_TOKEN" "$JIRA_URL/rest/api/3/issue/$TICKET_ID"
```

### Complete Credential Extraction Function

```bash
get_jira_credentials() {
    python3 -c "
import json
with open('$HOME/.claude/mcp.json') as f:
    config = json.load(f)
    env = config['mcpServers']['mcp-atlassian']['env']
    print(env['JIRA_USERNAME'])
    print(env['JIRA_API_TOKEN'])
"
}

# Use credentials securely
IFS=$'\n' read -d '' -r JIRA_USERNAME JIRA_API_TOKEN < <(get_jira_credentials && printf '\0')
```

## Section 4: Sequential Processing Model (INFRA-01)

Process tickets one at a time to eliminate race conditions. Sequential model makes file locking mechanisms unnecessary.

### Filesystem Safety Patterns

- **Process tickets one at a time** - No parallel fetches
- **Use `mkdir -p` for directory creation** - Atomic operation
- **Check directory existence after creation** - Defensive measure
- **No flock, no file locking mechanisms needed** - Sequential model eliminates races

### Directory Creation Pattern

```bash
mkdir -p "$TICKET_DIR" || true
if [ ! -d "$TICKET_DIR" ]; then
    echo "ERROR: Failed to create $TICKET_DIR" >&2
    exit 1
fi
```

### Complete Sequential Fetch Pattern

```bash
fetch_ticket_sequentially() {
    local ticket_id="$1"
    local ticket_dir="./todo/$ticket_id"

    # Create directory structure (atomic)
    mkdir -p "$ticket_dir/assets" || true
    mkdir -p "$ticket_dir/context" || true

    # Verify directories exist
    if [ ! -d "$ticket_dir" ]; then
        echo "ERROR: Failed to create $ticket_dir" >&2
        exit 1
    fi

    # Sequential fetches (one source at a time)
    fetch_jira "$ticket_id" "$ticket_dir"
    fetch_confluence "$ticket_id" "$ticket_dir"
    fetch_figma "$ticket_id" "$ticket_dir"
    fetch_github "$ticket_id" "$ticket_dir"

    echo "Ticket fetched to $ticket_dir"
}
```

### Why Sequential Processing Satisfies INFRA-01

The sequential processing model eliminates race conditions by design:

- **One ticket at a time** - No concurrent writes to the same directory
- **One source at a time** - No concurrent writes to the same file
- **mkdir -p is atomic** - Kernel guarantees directory creation is atomic
- **No need for flock** - File locking only needed for concurrent access

INFRA-01 requirement (atomic file operations to prevent race conditions) is satisfied by ensuring operations never overlap.

# Agent Handoff State File

Format and creation instructions for `.state.json` files that communicate ticket fetch results to downstream agents (INFRA-05).

## Section 1: State File Location and Purpose

### Location

State file path: `todo/MT-XXXX/.state.json` (inside the ticket directory)

### Purpose

The state file is the contract between the ticket intake skill and all downstream consumers. Downstream agents (work executor, planner) read this file to understand:

- What context was successfully gathered
- What is missing or failed to fetch
- Whether the ticket is ready for planning

### Readiness Contract

A ticket is "ready for planning" only when:
1. `.state.json` exists in the ticket directory
2. `ready_for_planning` field is `true`

## Section 2: State File Schema

The exact JSON structure that must be generated:

```json
{
  "ticket_id": "MT-XXXX",
  "fetched_at": "2026-03-25T14:30:00Z",
  "sources": {
    "jira": {
      "status": "success|failed|skipped",
      "file": "TICKET_DESCRIPTION.md",
      "error": null
    },
    "confluence": {
      "status": "success|failed|skipped",
      "files": ["context/confluence-PAGE_ID.md"],
      "error": null
    },
    "figma": {
      "status": "success|failed|skipped",
      "files": ["context/figma-FILE_KEY.json"],
      "error": null
    },
    "github": {
      "status": "success|failed|skipped",
      "files": ["context/github-pr-NUMBER.md"],
      "error": null
    }
  },
  "links_preserved": true,
  "ready_for_planning": true
}
```

### Field Descriptions

- **ticket_id** - The Jira ticket identifier (e.g., "MT-9550")
- **fetched_at** - ISO 8601 timestamp of when the fetch completed
- **sources** - Status and output files for each data source
- **links_preserved** - Boolean indicating whether all original links were preserved in TICKET_DESCRIPTION.md
- **ready_for_planning** - Boolean indicating whether the ticket has sufficient context to proceed

## Section 3: Status Values

Each source's `status` field must be one of three values:

### "success"

Data was fetched and saved to the listed files.

Example:
```json
"jira": {
  "status": "success",
  "file": "TICKET_DESCRIPTION.md",
  "error": null
}
```

### "failed"

MCP call failed after all retry attempts. The `error` field contains the failure reason.

**Important:** Never include credential data in error messages.

Example:
```json
"figma": {
  "status": "failed",
  "files": [],
  "error": "MCP timeout after 3 retries"
}
```

Common failure reasons:
- "MCP timeout after 3 retries"
- "Server returned isError"
- "Invalid response - missing required fields"
- "Network unreachable"

### "skipped"

No links of this type were found in the ticket (nothing to fetch).

Example:
```json
"github": {
  "status": "skipped",
  "files": [],
  "error": null
}
```

## Section 4: Ready-for-Planning Logic

The `ready_for_planning` field determines whether downstream agents can proceed.

### Logic

```
ready_for_planning = true IF sources.jira.status == "success"
ready_for_planning = false IF sources.jira.status != "success"
```

### Rationale

- **Jira is the only critical source** - The ticket description and acceptance criteria are essential
- **Other sources are best-effort** - Confluence, Figma, and GitHub provide supplementary context
- **Graceful degradation** - Even if Confluence, Figma, or GitHub fail, the ticket is still plannable

### Examples

**Scenario 1: All sources succeed**
```json
{
  "sources": {
    "jira": { "status": "success" },
    "confluence": { "status": "success" },
    "figma": { "status": "success" },
    "github": { "status": "success" }
  },
  "ready_for_planning": true
}
```

**Scenario 2: Jira succeeds, Figma fails**
```json
{
  "sources": {
    "jira": { "status": "success" },
    "confluence": { "status": "success" },
    "figma": { "status": "failed", "error": "MCP timeout" },
    "github": { "status": "skipped" }
  },
  "ready_for_planning": true
}
```

**Scenario 3: Jira fails**
```json
{
  "sources": {
    "jira": { "status": "failed", "error": "Server unreachable" },
    "confluence": { "status": "skipped" },
    "figma": { "status": "skipped" },
    "github": { "status": "skipped" }
  },
  "ready_for_planning": false
}
```

## Section 5: State File Creation Pattern

Use this bash function to create state files with proper JSON formatting:

```bash
create_state_file() {
    local ticket_dir="$1"
    local ticket_id="$2"
    local jira_status="$3"
    local jira_error="${4:-null}"
    local confluence_status="${5:-skipped}"
    local confluence_error="${6:-null}"
    local figma_status="${7:-skipped}"
    local figma_error="${8:-null}"
    local github_status="${9:-skipped}"
    local github_error="${10:-null}"

    local ready="false"
    [ "$jira_status" = "success" ] && ready="true"

    python3 -c "
import json, glob, os
state = {
    'ticket_id': '$ticket_id',
    'fetched_at': '$(date -u +\"%Y-%m-%dT%H:%M:%SZ\")',
    'sources': {
        'jira': {'status': '$jira_status', 'file': 'TICKET_DESCRIPTION.md', 'error': $jira_error},
        'confluence': {'status': '$confluence_status', 'files': sorted(glob.glob('$ticket_dir/context/confluence-*.md')), 'error': $confluence_error},
        'figma': {'status': '$figma_status', 'files': sorted(glob.glob('$ticket_dir/context/figma-*.json')), 'error': $figma_error},
        'github': {'status': '$github_status', 'files': sorted(glob.glob('$ticket_dir/context/github-*.md')), 'error': $github_error}
    },
    'links_preserved': os.path.exists('$ticket_dir/TICKET_DESCRIPTION.md'),
    'ready_for_planning': $ready
}
with open('$ticket_dir/.state.json', 'w') as f:
    json.dump(state, f, indent=2)
print('State file created: $ticket_dir/.state.json')
"
}
```

### Usage Example

```bash
# Successful Jira fetch, Figma failed, others skipped
create_state_file \
    "./todo/MT-9550" \
    "MT-9550" \
    "success" \
    "null" \
    "skipped" \
    "null" \
    "failed" \
    '"MCP timeout after 1 retry"' \
    "skipped" \
    "null"
```

### Error Message Formatting

When passing error messages to `create_state_file`, ensure they are properly quoted JSON strings:

```bash
# Good: Properly quoted JSON string
create_state_file "$DIR" "$ID" "failed" '"Server unreachable"'

# Bad: Unquoted string (invalid JSON)
create_state_file "$DIR" "$ID" "failed" "Server unreachable"

# Good: null for no error
create_state_file "$DIR" "$ID" "success" "null"
```

## Section 6: Reading State Files (for downstream agents)

Downstream agents should check the state file before proceeding with planning or execution.

### Check Readiness

```bash
# Check if ticket is ready for planning
is_ready=$(python3 -c "
import json
with open('todo/MT-XXXX/.state.json') as f:
    state = json.load(f)
    print(state['ready_for_planning'])
")

if [ "$is_ready" != "True" ]; then
    echo "ERROR: Ticket not ready for planning - Jira fetch failed"
    exit 1
fi
```

### Check Individual Source Status

```bash
# Check which sources succeeded
python3 -c "
import json
with open('todo/MT-XXXX/.state.json') as f:
    state = json.load(f)
    for source, data in state['sources'].items():
        status = data['status']
        files = data.get('files', []) or [data.get('file')]
        files = [f for f in files if f]
        print(f'{source}: {status} - {len(files)} files')
        if data.get('error'):
            print(f'  Error: {data[\"error\"]}')
"
```

### Extract File Paths

```bash
# Get all successfully fetched files
python3 -c "
import json
with open('todo/MT-XXXX/.state.json') as f:
    state = json.load(f)
    for source, data in state['sources'].items():
        if data['status'] == 'success':
            files = data.get('files', []) or [data.get('file')]
            for file in files:
                if file:
                    print(file)
"
```

### Complete Validation Example

```bash
validate_ticket_state() {
    local ticket_id="$1"
    local state_file="todo/$ticket_id/.state.json"

    if [ ! -f "$state_file" ]; then
        echo "ERROR: State file missing - ticket not fetched"
        return 1
    fi

    ready=$(python3 -c "import json; print(json.load(open('$state_file'))['ready_for_planning'])")

    if [ "$ready" != "True" ]; then
        echo "ERROR: Ticket not ready for planning"
        python3 -c "
import json
state = json.load(open('$state_file'))
jira = state['sources']['jira']
print(f'Jira status: {jira[\"status\"]}')
if jira.get('error'):
    print(f'Jira error: {jira[\"error\"]}')
"
        return 1
    fi

    echo "Ticket validated and ready for planning"
    return 0
}
```

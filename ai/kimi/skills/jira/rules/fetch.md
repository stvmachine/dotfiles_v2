# Ticket Fetch Rule

Core logic for fetching a Jira ticket, downloading attachments, and creating the structured ticket directory. Covers INTAKE-01, INTAKE-02, INTAKE-07.

## Section 0: Centralized Storage Initialization

Initialize the centralized storage system in `~/.medtasker-tickets/`.

```bash
CENTRAL_DIR="$HOME/.medtasker-tickets"
INDEX_DIR="$CENTRAL_DIR/.index"
CACHE_DIR="$CENTRAL_DIR/.cache/confluence"

mkdir -p "$CENTRAL_DIR"
mkdir -p "$INDEX_DIR"
mkdir -p "$CACHE_DIR"

# Initialize Confluence deduplication index
CONFLUENCE_INDEX="$INDEX_DIR/confluence-index.json"
[ -f "$CONFLUENCE_INDEX" ] || echo '{}' > "$CONFLUENCE_INDEX"

echo "Centralized storage: $CENTRAL_DIR"
```

## Section 1: Directory Structure Creation (per D-01)

Create the ticket directory with organized subdirectories for different content types.

```bash
TICKET_ID="MT-XXXX"  # From user input
TICKET_DIR="./todo/$TICKET_ID"
CENTRAL_TICKET_DIR="$HOME/.medtasker-tickets/$TICKET_ID"

# Create local directory structure (per D-01: subdirectories for organization)
mkdir -p "$TICKET_DIR/assets"
mkdir -p "$TICKET_DIR/context"

# Create central directory structure
mkdir -p "$CENTRAL_TICKET_DIR/assets"
mkdir -p "$CENTRAL_TICKET_DIR/context"

# Verify directories were created successfully
if [ ! -d "$TICKET_DIR" ]; then
    echo "ERROR: Failed to create $TICKET_DIR" >&2
    exit 1
fi
```

**Directory naming:**
- `assets/` — images, documents, and attachments from Jira
- `context/` — Confluence pages, Figma design data, GitHub PR summaries
- **Centralized storage**: `~/.medtasker-tickets/MT-XXXX/` for persistent archive

**Overwrite mode:** If directory already exists, proceed normally (per D-04: re-fetch overwrites all content).

## Section 2: Jira Ticket Fetch (INTAKE-01)

Fetch the complete ticket data from Jira using the mcp-atlassian MCP server.

### Step-by-step instructions:

1. **Call the MCP tool** with full field expansion:
   ```bash
   mcp__mcp-atlassian__jira_get_issue \
     issue_key="$TICKET_ID" \
     fields="*all" \
     expand="renderedFields"
   ```

2. **Validate the response** using patterns from rules/mcp-utils.md:
   - Check `isError` flag
   - Verify `key` field exists
   - Verify `fields.summary` field exists

3. **Retry on failure** using retry_with_backoff from rules/mcp-utils.md:
   - 3 attempts for Jira
   - 30s initial delay, doubling each retry (30s, 60s, 120s)

4. **Extract critical fields** from the response:
   - `fields.summary` — ticket title
   - `fields.description` — ticket description (raw and rendered)
   - `renderedFields.description` — markdown-formatted description
   - `fields.status.name` — current status
   - `fields.issuetype.name` — issue type
   - `fields.assignee.displayName` — assignee name (may be null)
   - `fields.priority.name` — priority level
   - `fields.labels` — labels array
   - `fields.comment.comments` — all comments
   - `fields.issuelinks` — linked issues
   - `fields.subtasks` — subtask list
   - `fields.attachment` — attachment list (for INTAKE-02)

## Section 3: TICKET_DESCRIPTION.md Format

Create `$TICKET_DIR/TICKET_DESCRIPTION.md` with this exact structure. This format preserves ALL external links (INTAKE-07) in the References section.

```markdown
# $TICKET_ID: $SUMMARY

| Field | Value |
|-------|-------|
| **Status** | $STATUS |
| **Type** | $ISSUE_TYPE |
| **Assignee** | $ASSIGNEE |
| **Priority** | $PRIORITY |
| **Labels** | $LABELS (comma-separated) |

## Description

$RENDERED_DESCRIPTION

## Test Cases / Acceptance Criteria

$ACCEPTANCE_CRITERIA (extract from description if present, or mark as "See description above")

## Attachments

$FOR_EACH_ATTACHMENT:
- [`$FILENAME`](./assets/$FILENAME) ($SIZE_IN_KB KB) - $DESCRIPTION_IF_AVAILABLE

## References

### Jira
- Ticket: https://medtasker.atlassian.net/browse/$TICKET_ID

### Confluence
$FOR_EACH_CONFLUENCE_LINK:
- [$PAGE_TITLE]($CONFLUENCE_URL) → [Local](./context/confluence-$PAGE_ID.md)

### Figma
$FOR_EACH_FIGMA_LINK:
- [$DESCRIPTION]($FIGMA_URL) → [Local](./context/figma-$FILE_KEY.json)

### GitHub
$FOR_EACH_GITHUB_LINK:
- [$DESCRIPTION]($GITHUB_URL) → [Local](./context/github-$REF.md)

### Other Links
$FOR_EACH_OTHER_LINK:
- [$LINK_TEXT]($URL)

## Linked Issues

$FOR_EACH_LINK:
- $LINK_TYPE: $LINKED_KEY - $LINKED_SUMMARY [$LINKED_STATUS]

## Subtasks

$FOR_EACH_SUBTASK:
- [ ] $SUBTASK_KEY - $SUBTASK_SUMMARY [$SUBTASK_STATUS]

## Recent Comments

$FOR_LAST_3_COMMENTS:
---
**[$DATE]** $AUTHOR:
$COMMENT_BODY
```

**Important:** The References section preserves all external links with both original URLs and local file paths where applicable. This satisfies INTAKE-07.

## Section 4: Attachment Download (INTAKE-02)

Download ALL attachments from Jira to the `assets/` directory.

### Attachment Deduplication System

Attachments are stored per-ticket in the centralized storage. No deduplication is performed for Jira attachments (images, documents) as they are typically unique per ticket.

- **Storage location:** `~/.medtasker-tickets/MT-XXXX/assets/`
- **Local symlink:** `./todo/MT-XXXX/assets/` → `~/.medtasker-tickets/MT-XXXX/assets/`

**Confluence Deduplication (separate system):**
- Confluence pages are deduplicated across all tickets using a centralized index
- See Section 6: Confluence Deduplication for details

**Index entry format:**
```json
{
  "https://medtasker.atlassian.net/rest/api/3/attachment/content/12345": {
    "filename": "screenshot.png",
    "cached_path": "./.claude/jira-attachment-cache/screenshot-abc123.png",
    "size_bytes": 45678,
    "downloaded_at": "2026-04-01T13:38:01Z",
    "tickets": ["MT-9571"]
  }
}
```

### Instructions for downloading attachments:

1. **Extract attachment list** from Jira response `fields.attachment` array

2. **For each attachment**, download to centralized storage:
   ```bash
   ATTACHMENT_URL="https://medtasker.atlassian.net/rest/api/3/attachment/content/$ATTACHMENT_ID"
   FILENAME="$ATTACHMENT_FILENAME"
   CENTRAL_ASSETS="$HOME/.medtasker-tickets/$TICKET_ID/assets"
   
   # Read credentials using pattern from rules/mcp-utils.md
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
   
   # Download directly to centralized storage (note: leading space to prevent history exposure)
    curl -s -L -u "$JIRA_USERNAME:$JIRA_API_TOKEN" \
       -o "$CENTRAL_ASSETS/$FILENAME" \
       "$ATTACHMENT_URL"
   
   if [ -f "$CENTRAL_ASSETS/$FILENAME" ] && [ -s "$CENTRAL_ASSETS/$FILENAME" ]; then
       echo "Downloaded: $FILENAME"
   else
       echo "WARNING: Failed to download $FILENAME" >&2
   fi
   ```

3. **Create symlink in local working directory**:
   ```bash
   # Remove local assets directory if it exists
   rm -rf "$TICKET_DIR/assets"
   
   # Create symlink to centralized assets
   ln -s "$CENTRAL_ASSETS" "$TICKET_DIR/assets"
   ```

4. **Verify download** after each file:
   ```bash
   if [ -f "$CENTRAL_ASSETS/$FILENAME" ] && [ -s "$CENTRAL_ASSETS/$FILENAME" ]; then
       echo "OK: $FILENAME"
   else
       echo "WARNING: Failed to get $FILENAME" >&2
   fi
   ```

5. **Continue on failure** (partial context resilience per D-03):
   - If one attachment fails, log warning and continue with remaining attachments
   - Do NOT exit/abort on attachment failure
   - Mark failed downloads in state file

6. **Display images** after all downloads complete:
   - Use the Read tool to display each image attachment inline
   - This provides immediate visual context to the user

## Section 5: Link Extraction for Downstream Rules

After creating TICKET_DESCRIPTION.md, scan the full ticket content (description + comments) for external links and route to appropriate downstream rules.

### Link patterns to detect:

**Confluence links:**
- Pattern: `https://*.atlassian.net/wiki/spaces/*/pages/*`
- Pattern: `https://*.atlassian.net/wiki/x/*` (short links)
- Extract page IDs and pass to `rules/confluence.md`

**Figma links:**
- Pattern: `https://*.figma.com/file/*`
- Pattern: `https://*.figma.com/design/*`
- Extract file keys and pass to `rules/figma-integration.md`

**GitHub links:**
- Pattern: `https://github.com/*/*/pull/*` (PRs)
- Pattern: `https://github.com/*/*/issues/*` (Issues)
- Pattern: `https://github.com/*/*` (Repos)
- Extract references and pass to `rules/github.md`

**Other links:**
- Any URL not matching above patterns
- Preserve in the References > Other Links section

### Extraction process:

```bash
# Extract all URLs from description and comments
URLS=$(python3 -c "
import re, json, sys
# Read ticket JSON from stdin
ticket = json.load(sys.stdin)
description = ticket.get('fields', {}).get('description', '')
comments = ticket.get('fields', {}).get('comment', {}).get('comments', [])

# Extract URLs from description
urls = re.findall(r'https?://[^\s<>\"]+', description)

# Extract URLs from comments
for comment in comments:
    body = comment.get('body', '')
    urls.extend(re.findall(r'https?://[^\s<>\"]+', body))

# Print unique URLs
for url in set(urls):
    print(url)
" <<< "$JIRA_RESPONSE")

# Route to appropriate handlers
echo "$URLS" | while read -r url; do
    if [[ "$url" =~ atlassian\.net/wiki ]]; then
        # Confluence link found - will be handled by rules/confluence.md
        echo "Confluence: $url"
    elif [[ "$url" =~ figma\.com/(file|design) ]]; then
        # Figma link found - will be handled by rules/figma-integration.md
        echo "Figma: $url"
    elif [[ "$url" =~ github\.com ]]; then
        # GitHub link found - will be handled by rules/github.md
        echo "GitHub: $url"
    else
        # Other link - just preserve in TICKET_DESCRIPTION.md
        echo "Other: $url"
    fi
done
```

## Section 6: Confluence Deduplication (INTAKE-08)

Confluence pages are deduplicated across all tickets using a centralized index.

### Check Confluence Cache

```bash
CONFLUENCE_URL="$1"
INDEX_FILE="$HOME/.medtasker-tickets/.index/confluence-index.json"

# Check if already cached
CACHED_INFO=$(python3 -c "
import json, sys
try:
    index = json.load(open('$INDEX_FILE'))
    entry = index.get('$CONFLUENCE_URL')
    if entry:
        print(json.dumps(entry))
except: pass
" 2>/dev/null)

if [ -n "$CACHED_INFO" ]; then
    CACHED_PATH=$(echo "$CACHED_INFO" | python3 -c "import json,sys; print(json.load(sys.stdin)['cached_path'])")
    CACHED_PATH="${CACHED_PATH/#\~/$HOME}"
    
    if [ -f "$CACHED_PATH" ]; then
        echo "CACHED: $CONFLUENCE_URL"
        return 0
    fi
fi

return 1
```

### Update Confluence Index

```bash
CONFLUENCE_URL="$1"
PAGE_ID="$2"
TITLE="$3"
TICKET_ID="$4"
INDEX_FILE="$HOME/.medtasker-tickets/.index/confluence-index.json"
CACHE_DIR="$HOME/.medtasker-tickets/.cache/confluence"

python3 -c "
import json, os
index = json.load(open('$INDEX_FILE')) if os.path.exists('$INDEX_FILE') else {}

if '$CONFLUENCE_URL' not in index:
    index['$CONFLUENCE_URL'] = {
        'page_id': '$PAGE_ID',
        'title': '$TITLE',
        'cached_path': '~/.medtasker-tickets/.cache/confluence/$PAGE_ID.md',
        'downloaded_at': '$(date -u +"%Y-%m-%dT%H:%M:%SZ")',
        'tickets': ['$TICKET_ID']
    }
else:
    if '$TICKET_ID' not in index['$CONFLUENCE_URL']['tickets']:
        index['$CONFLUENCE_URL']['tickets'].append('$TICKET_ID')

json.dump(index, open('$INDEX_FILE', 'w'), indent=2)
"
```

## Section 7: Beads Integration (INTAKE-09)

Create a beads task for persistent tracking.

### Create Beads Task

```bash
TICKET_ID="$1"
TICKET_SUMMARY="$2"
JIRA_STATUS="$3"
JIRA_PRIORITY="$4"
ASSIGNEE="$5"
DESCRIPTION="$6"

# Map priority
PRIORITY_FLAG="-p 2"
if [[ "$JIRA_PRIORITY" =~ (Highest|Critical) ]]; then
    PRIORITY_FLAG="-p 0"
elif [[ "$JIRA_PRIORITY" =~ High ]]; then
    PRIORITY_FLAG="-p 1"
elif [[ "$JIRA_PRIORITY" =~ Low ]]; then
    PRIORITY_FLAG="-p 3"
fi

# Create beads task
BEADS_TASK=$(bd create "[$TICKET_ID] $TICKET_SUMMARY" $PRIORITY_FLAG --json 2>/dev/null)
BEADS_ID=$(echo "$BEADS_TASK" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('id',''))" 2>/dev/null)

if [ -n "$BEADS_ID" ]; then
    # Update body with details
    bd update "$BEADS_ID" --body "$(cat <<EOF
Jira Ticket: [$TICKET_ID](https://medtasker.atlassian.net/browse/$TICKET_ID)
Status: $JIRA_STATUS
Assignee: ${ASSIGNEE:-unassigned}

## Description
$DESCRIPTION

## Local Assets
- Description: ~/.medtasker-tickets/$TICKET_ID/TICKET_DESCRIPTION.md
- Assets: ~/.medtasker-tickets/$TICKET_ID/assets/
- Context: ~/.medtasker-tickets/$TICKET_ID/context/

## GitHub PRs
<!-- Updated by /ship-to-qa -->

## Notes
<!-- Agent coordination notes -->
EOF
)" 2>/dev/null
    
    echo "Beads task: $BEADS_ID"
fi
```

## Section 8: Completion

After all fetch operations complete:

1. **Copy ticket to centralized storage**:
   ```bash
   # Copy all content from local to central
   cp "$TICKET_DIR/TICKET_DESCRIPTION.md" "$CENTRAL_TICKET_DIR/"
   cp -r "$TICKET_DIR/context/"* "$CENTRAL_TICKET_DIR/context/" 2>/dev/null || true
   cp "$TICKET_DIR/.state.json" "$CENTRAL_TICKET_DIR/" 2>/dev/null || true
   ```

2. **Invoke state file creation** from rules/state-file.md:
   ```bash
   # See rules/state-file.md for create_state_file function definition
   create_state_file \
       "$TICKET_DIR" \
       "$TICKET_ID" \
       "success" \
       "null" \
       "$CONFLUENCE_STATUS" \
       "$CONFLUENCE_ERROR" \
       "$FIGMA_STATUS" \
       "$FIGMA_ERROR" \
       "$GITHUB_STATUS" \
       "$GITHUB_ERROR"
   ```

3. **Create beads task** (if beads is available):
   ```bash
   if command -v bd &> /dev/null && [ -d ".beads" ]; then
       create_beads_task "$TICKET_ID" "$SUMMARY" "$STATUS" "$PRIORITY" "$ASSIGNEE" "$DESCRIPTION"
   fi
   ```

4. **Display summary** to user:
   ```
   ✓ Ticket fetched: todo/$TICKET_ID/
     • TICKET_DESCRIPTION.md (created)
     • assets/ (N files downloaded) → ~/.medtasker-tickets/$TICKET_ID/assets/
     • context/ (populated by downstream rules)
     • .state.json (created)
     • beads task: $BEADS_ID (if created)

   Storage:
     • Local: ./todo/$TICKET_ID/
     • Central: ~/.medtasker-tickets/$TICKET_ID/

   Links found:
     • N Confluence pages (cached: M)
     • N Figma designs
     • N GitHub references

   Next: Downstream rules will fetch additional context from linked sources.
   ```

**Note:** The state file's `ready_for_planning` flag is set based solely on Jira fetch success (per rules/state-file.md). Confluence, Figma, and GitHub are supplementary — their failure doesn't block planning.

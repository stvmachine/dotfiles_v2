# Ticket Fetch Rule

Core logic for fetching a Jira ticket, downloading attachments, and creating the structured ticket directory. Covers INTAKE-01, INTAKE-02, INTAKE-07.

## Section 1: Directory Structure Creation (per D-01)

Create the ticket directory with organized subdirectories for different content types.

```bash
TICKET_ID="MT-XXXX"  # From user input
TICKET_DIR="./todo/$TICKET_ID"

# Create directory structure (per D-01: subdirectories for organization)
mkdir -p "$TICKET_DIR/assets"
mkdir -p "$TICKET_DIR/context"

# Verify directories were created successfully
if [ ! -d "$TICKET_DIR" ]; then
    echo "ERROR: Failed to create $TICKET_DIR" >&2
    exit 1
fi
```

**Directory naming:**
- `assets/` — images, documents, and attachments from Jira
- `context/` — Confluence pages, Figma design data, GitHub PR summaries

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

### Instructions for downloading attachments:

1. **Extract attachment list** from Jira response `fields.attachment` array

2. **For each attachment**, download using curl with authentication:

   ```bash
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

   # Download attachment (note: leading space to prevent history exposure)
    curl -s -L -u "$JIRA_USERNAME:$JIRA_API_TOKEN" \
       -o "$TICKET_DIR/assets/$FILENAME" \
       "https://medtasker.atlassian.net/rest/api/3/attachment/content/$ATTACHMENT_ID"
   ```

3. **Verify download** after each file:
   ```bash
   if [ -f "$TICKET_DIR/assets/$FILENAME" ] && [ -s "$TICKET_DIR/assets/$FILENAME" ]; then
       echo "Downloaded: $FILENAME"
   else
       echo "WARNING: Failed to download $FILENAME" >&2
   fi
   ```

4. **Continue on failure** (partial context resilience per D-03):
   - If one attachment fails, log warning and continue with remaining attachments
   - Do NOT exit/abort on attachment failure
   - Mark failed downloads in state file

5. **Display images** after all downloads complete:
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

## Section 6: Completion

After all fetch operations complete:

1. **Invoke state file creation** from rules/state-file.md:
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

2. **Display summary** to user:
   ```
   ✓ Ticket fetched: todo/$TICKET_ID/
     • TICKET_DESCRIPTION.md (created)
     • assets/ (N files downloaded)
     • context/ (populated by downstream rules)
     • .state.json (created)

   Links found:
     • N Confluence pages
     • N Figma designs
     • N GitHub references

   Next: Downstream rules will fetch additional context from linked sources.
   ```

**Note:** The state file's `ready_for_planning` flag is set based solely on Jira fetch success (per rules/state-file.md). Confluence, Figma, and GitHub are supplementary — their failure doesn't block planning.

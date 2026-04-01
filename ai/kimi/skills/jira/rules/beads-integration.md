# Beads Integration Rule

Integrates Jira ticket workflow with beads for persistent task tracking and multi-agent coordination. Covers BEADS-01 through BEADS-05.

## Overview

Beads augments the markdown-based ticket system by providing:
- **Persistent task tracking** across git branches and sessions
- **Multi-agent coordination** via `bd claim`, `bd dep add`, etc.
- **GitHub PR linking** for traceability
- **Asset reference tracking** (local paths to downloaded files)
- **Status synchronization** between Jira and local workflow

## Storage Architecture

```
~/.medtasker-tickets/
├── .index/
│   └── confluence-index.json     # Deduplication index for Confluence pages
├── MT-XXXX/                       # Archived tickets (moved from ./todo/)
│   ├── TICKET_DESCRIPTION.md
│   ├── assets/
│   └── context/
└── MT-YYYY/
    └── ...

./todo/                            # Working cache (gitignored)
└── MT-XXXX/                       # Symlinked or copied from ~/.medtasker-tickets/
    ├── TICKET_DESCRIPTION.md
    ├── assets/                    # Symlinked to ~/.medtasker-tickets/MT-XXXX/assets/
    ├── context/
    └── .state.json

.beads/                            # Beads database (stealth mode)
└── beads.db                       # SQLite database with tasks
```

## Section 1: Beads Initialization (BEADS-01)

Ensure beads is initialized in the project before use.

### Check Initialization

```bash
if [ ! -d ".beads" ]; then
    echo "Beads not initialized. Running: bd init --stealth"
    bd init --stealth
fi
```

### Verify beads is working

```bash
bd ready --json > /dev/null 2>&1 || {
    echo "ERROR: beads CLI not working. Install with: brew install beads"
    exit 1
}
```

## Section 2: Create Beads Task for Jira Ticket (BEADS-02)

When fetching a Jira ticket via `/jira inbox`, create a corresponding beads task.

### Task Creation Pattern

```bash
TICKET_ID="MT-XXXX"
TICKET_SUMMARY="[Dispatcher Phase 1] Mobile: Block task coordinator roles..."
JIRA_STATUS="Ready for Dev"

# Create beads task with Jira ticket ID in title
# Priority mapping: Jira priority -> beads priority (P0-P3)
# Highest/Critical -> P0
# High -> P1  
# Medium -> P2
# Low/Lowest -> P3

PRIORITY_FLAG="-p 2"  # Default P2
if [[ "$JIRA_PRIORITY" =~ (Highest|Critical) ]]; then
    PRIORITY_FLAG="-p 0"
elif [[ "$JIRA_PRIORITY" =~ High ]]; then
    PRIORITY_FLAG="-p 1"
elif [[ "$JIRA_PRIORITY" =~ Low ]]; then
    PRIORITY_FLAG="-p 3"
fi

# Create the task
BEADS_TASK=$(bd create "[$TICKET_ID] $TICKET_SUMMARY" $PRIORITY_FLAG --json)
BEADS_ID=$(echo "$BEADS_TASK" | python3 -c "import json,sys; print(json.load(sys.stdin)['id'])")

echo "Created beads task: $BEADS_ID"
```

### Task Body Format

The beads task body should include:

```markdown
Jira Ticket: [$TICKET_ID](https://medtasker.atlassian.net/browse/$TICKET_ID)
Status: $JIRA_STATUS
Assignee: $ASSIGNEE

## Description
$TICKET_DESCRIPTION

## Local Assets
- Description: ~/.medtasker-tickets/$TICKET_ID/TICKET_DESCRIPTION.md
- Assets: ~/.medtasker-tickets/$TICKET_ID/assets/
- Context: ~/.medtasker-tickets/$TICKET_ID/context/

## GitHub PRs
<!-- Updated by /ship-to-qa -->

## Notes
<!-- Agent coordination notes -->
```

### Update beads task body

```bash
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
)"
```

## Section 3: Centralized Storage Setup (BEADS-03)

Set up the centralized storage in `~/.medtasker-tickets/`.

### Initialize Centralized Storage

```bash
CENTRAL_DIR="$HOME/.medtasker-tickets"
INDEX_DIR="$CENTRAL_DIR/.index"

mkdir -p "$CENTRAL_DIR"
mkdir -p "$INDEX_DIR"

# Initialize Confluence deduplication index
CONFLUENCE_INDEX="$INDEX_DIR/confluence-index.json"
[ -f "$CONFLUENCE_INDEX" ] || echo '{}' > "$CONFLUENCE_INDEX"

echo "Centralized storage: $CENTRAL_DIR"
```

### Copy Ticket to Centralized Storage

When fetching a ticket, store it in the centralized location:

```bash
TICKET_ID="MT-XXXX"
CENTRAL_TICKET_DIR="$HOME/.medtasker-tickets/$TICKET_ID"
LOCAL_TICKET_DIR="./todo/$TICKET_ID"

# Create central directory
mkdir -p "$CENTRAL_TICKET_DIR/assets"
mkdir -p "$CENTRAL_TICKET_DIR/context"

# Copy ticket description
cp "$LOCAL_TICKET_DIR/TICKET_DESCRIPTION.md" "$CENTRAL_TICKET_DIR/"

# Copy assets (if not using symlinks)
cp -r "$LOCAL_TICKET_DIR/assets/"* "$CENTRAL_TICKET_DIR/assets/" 2>/dev/null || true

# Copy context
cp -r "$LOCAL_TICKET_DIR/context/"* "$CENTRAL_TICKET_DIR/context/" 2>/dev/null || true

# Copy state file
cp "$LOCAL_TICKET_DIR/.state.json" "$CENTRAL_TICKET_DIR/" 2>/dev/null || true
```

### Symlink Local to Central (Optional)

For space efficiency, symlink the local working cache to central storage:

```bash
# Remove local assets if they exist
rm -rf "$LOCAL_TICKET_DIR/assets"

# Create symlink to central assets
ln -s "$CENTRAL_TICKET_DIR/assets" "$LOCAL_TICKET_DIR/assets"
```

## Section 4: Confluence Deduplication Index (BEADS-04)

Maintain a cross-project index for Confluence pages to avoid re-downloading.

### Index Structure

```json
{
  "https://medtasker.atlassian.net/wiki/spaces/MT/pages/3839492116/DispatcherPhase1": {
    "page_id": "3839492116",
    "title": "Dispatcher Phase 1: How might it work technically",
    "cached_path": "~/.medtasker-tickets/.cache/confluence/3839492116.md",
    "downloaded_at": "2026-04-01T13:38:01Z",
    "tickets": ["MT-9571", "MT-9572"]
  }
}
```

### Check Index Before Download

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
    # Expand ~ to $HOME
    CACHED_PATH="${CACHED_PATH/#\~/$HOME}"
    
    if [ -f "$CACHED_PATH" ]; then
        echo "CACHED: $CONFLUENCE_URL"
        echo "$CACHED_INFO"
        return 0
    fi
fi

return 1
```

### Update Index After Download

```bash
CONFLUENCE_URL="$1"
PAGE_ID="$2"
TITLE="$3"
CACHE_PATH="$HOME/.medtasker-tickets/.cache/confluence/$PAGE_ID.md"
TICKET_ID="$4"

python3 -c "
import json, os
index_file = '$HOME/.medtasker-tickets/.index/confluence-index.json'
index = json.load(open(index_file)) if os.path.exists(index_file) else {}

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

json.dump(index, open(index_file, 'w'), indent=2)
"
```

## Section 5: Multi-Agent Coordination (BEADS-05)

Use beads features for coordinating between multiple agents.

### Claim a Task

When starting work on a ticket:

```bash
BEADS_ID="bd-xxxxx"
AGENT_NAME="${BEADS_AGENT:-$(whoami)}"

# Claim the task (atomically sets assignee + in_progress)
bd update "$BEADS_ID" --claim

# Add agent identifier to notes
bd update "$BEADS_ID" --body-append "

**Claimed by:** $AGENT_NAME at $(date -u +"%Y-%m-%dT%H:%M:%SZ")
"
```

### Add Dependencies

When a ticket depends on another:

```bash
CHILD_BEADS_ID="bd-xxxxx"
PARENT_BEADS_ID="bd-yyyyy"

# Link child to parent (child is blocked by parent)
bd dep add "$CHILD_BEADS_ID" "$PARENT_BEADS_ID"
```

### Update Status

Sync beads status with Jira transitions:

```bash
BEADS_ID="bd-xxxxx"
NEW_STATUS="$1"  # e.g., "in_progress", "in_review", "done"

case "$NEW_STATUS" in
    "in_progress")
        bd update "$BEADS_ID" --status "in_progress"
        ;;
    "in_review")
        bd update "$BEADS_ID" --status "in_review"
        ;;
    "done"|"closed")
        bd close "$BEADS_ID" "Shipped to QA"
        ;;
esac
```

### Link GitHub PR

When a PR is created (called by `/ship-to-qa`):

```bash
BEADS_ID="bd-xxxxx"
PR_URL="$1"
PR_TITLE="$2"

# Update task body with PR link
bd update "$BEADS_ID" --body-append "

## GitHub PRs
- [$PR_TITLE]($PR_URL) - $(date -u +"%Y-%m-%dT%H:%M:%SZ")
"
```

## Section 6: Archive Completed Tickets (BEADS-06)

Move completed tickets from local working cache to centralized archive.

### Archive Workflow

```bash
TICKET_ID="MT-XXXX"
LOCAL_DIR="./todo/$TICKET_ID"
CENTRAL_DIR="$HOME/.medtasker-tickets/$TICKET_ID"

# Ensure central directory exists
mkdir -p "$CENTRAL_DIR"

# Move all content to central storage
mv "$LOCAL_DIR/"* "$CENTRAL_DIR/" 2>/dev/null || true

# Remove local directory
rm -rf "$LOCAL_DIR"

# Update beads task status
BEADS_ID=$(get_beads_id_for_ticket "$TICKET_ID")
if [ -n "$BEADS_ID" ]; then
    bd close "$BEADS_ID" "Archived to ~/.medtasker-tickets/$TICKET_ID"
fi

echo "Archived $TICKET_ID to $CENTRAL_DIR"
```

### Find Beads ID for Jira Ticket

```bash
get_beads_id_for_ticket() {
    local ticket_id="$1"
    
    # Search beads tasks by title containing the ticket ID
    bd list --json | python3 -c "
import json, sys, re
tasks = json.load(sys.stdin)
for task in tasks:
    title = task.get('title', '')
    if re.search(r'\[$ticket_id\]', title):
        print(task['id'])
        sys.exit(0)
print('')
"
}
```

## Section 7: Integration with /ship-to-qa (BEADS-07)

When `/ship-to-qa` runs, update both Jira and beads.

### Ship-to-QA Beads Updates

```bash
# Called by /ship-to-qa after PR creation

TICKET_ID="$1"
PR_URL="$2"
PR_TITLE="$3"

# Find beads task
BEADS_ID=$(get_beads_id_for_ticket "$TICKET_ID")

if [ -n "$BEADS_ID" ]; then
    # Link PR
    bd update "$BEADS_ID" --body-append "

## GitHub PRs
- [$PR_TITLE]($PR_URL) - $(date -u +"%Y-%m-%dT%H:%M:%SZ")
"
    
    # Update status to in_review
    bd update "$BEADS_ID" --status "in_review"
    
    echo "Updated beads task $BEADS_ID with PR link"
fi
```

## Section 8: Cache Management

### List Centralized Storage Stats

```bash
python3 <<EOF
import json, os
from pathlib import Path

central_dir = Path.home() / ".medtasker-tickets"
index_file = central_dir / ".index" / "confluence-index.json"

# Count tickets
tickets = [d for d in central_dir.iterdir() if d.is_dir() and not d.name.startswith('.')]
print(f"Archived tickets: {len(tickets)}")

# Count Confluence cache
if index_file.exists():
    index = json.load(open(index_file))
    print(f"Cached Confluence pages: {len(index)}")
    
    # Count unique tickets referencing Confluence
    all_tickets = set()
    for entry in index.values():
        all_tickets.update(entry.get('tickets', []))
    print(f"Tickets with Confluence refs: {len(all_tickets)}")
else:
    print("Confluence cache: empty")
EOF
```

### Clean Orphaned Cache Entries

```bash
python3 <<EOF
import json, os
from pathlib import Path

central_dir = Path.home() / ".medtasker-tickets"
index_file = central_dir / ".index" / "confluence-index.json"

if not index_file.exists():
    print("No index file found")
    exit(0)

index = json.load(open(index_file))

# Find all existing ticket IDs
existing_tickets = set()
for d in central_dir.iterdir():
    if d.is_dir() and not d.name.startswith('.'):
        existing_tickets.add(d.name)

# Remove references to non-existent tickets
for url, entry in list(index.items()):
    original_count = len(entry['tickets'])
    entry['tickets'] = [t for t in entry['tickets'] if t in existing_tickets]
    if not entry['tickets']:
        # Remove cache file if no tickets reference it
        cache_path = entry['cached_path'].replace('~', str(Path.home()))
        if os.path.exists(cache_path):
            os.remove(cache_path)
            print(f"Removed orphaned cache: {cache_path}")
        del index[url]
    elif len(entry['tickets']) < original_count:
        print(f"Cleaned references for: {entry['title']}")

json.dump(index, open(index_file, 'w'), indent=2)
print("Cache cleanup complete")
EOF
```

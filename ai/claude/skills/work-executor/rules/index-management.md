# INDEX.md Management

Read, write, and update patterns for the ticket inbox queue file (`todo/INDEX.md`). All operations use atomic temp-file-then-rename to prevent corruption.

## INDEX.md Location

File path: `todo/INDEX.md`

This file is the persistent queue index for all tickets fetched via `/jira inbox`. It is the single source of truth for ticket status and ordering.

## Table Format

The exact markdown table format for INDEX.md:

```markdown
# Ticket Inbox Queue

**Last Updated:** {ISO 8601 timestamp}

| Ticket | Status | Priority | Fetched | Context Ready |
|--------|--------|----------|---------|---------------|
| MT-XXXX | ready | high | 2026-03-25 | yes |

**Oldest ready:** MT-XXXX ({N} days)
**Total ready:** {N} | **In progress:** {N}
```

## Status Values

Each ticket row has one of these status values:

| Status | Meaning |
|--------|---------|
| `ready` | Ticket fetched and available for work |
| `in-progress` | Ticket currently being worked on |
| `completed` | Work finished and merged |
| `abandoned` | Ticket dropped from queue |

## Missing INDEX.md

If work-executor finds no INDEX.md, print the D-03 error and exit:

```
ERROR: No tickets in queue. Run '/jira inbox MT-XXXX' to fetch a Jira ticket first.
```

The jira skill creates INDEX.md when a user runs `/jira inbox`. The work-executor skill never creates INDEX.md from scratch -- it only reads and updates it.

## Reading INDEX.md

Parse the markdown table to extract ticket rows:

```bash
INDEX_FILE="todo/INDEX.md"

# Check existence
if [ ! -f "$INDEX_FILE" ]; then
    echo "ERROR: No tickets in queue. Run '/jira inbox MT-XXXX' to fetch a Jira ticket first."
    exit 1
fi

# Extract data rows (skip header and separator lines)
ROWS=$(grep -E '^\| MT-' "$INDEX_FILE")

# Parse individual columns from a row
echo "$ROWS" | while IFS='|' read -r _ ticket status priority fetched context_ready _; do
    ticket=$(echo "$ticket" | xargs)
    status=$(echo "$status" | xargs)
    priority=$(echo "$priority" | xargs)
    fetched=$(echo "$fetched" | xargs)
    context_ready=$(echo "$context_ready" | xargs)
    echo "Ticket: $ticket, Status: $status, Priority: $priority, Fetched: $fetched, Ready: $context_ready"
done
```

## Filter Ready Tickets

```bash
# Get only tickets with status = ready
READY_ROWS=$(grep -E '^\| MT-' "$INDEX_FILE" | grep '| ready |')

# Count ready tickets
READY_COUNT=$(echo "$READY_ROWS" | grep -c '| ready |' 2>/dev/null || echo "0")

# Get oldest ready ticket (first row, since table is ordered oldest-first)
OLDEST_TICKET=$(echo "$READY_ROWS" | head -1 | awk -F'|' '{print $2}' | xargs)
```

## Atomic Update Pattern

Never modify INDEX.md in-place. Always use the temp-file-then-rename pattern:

```bash
# 1. Read current content
CURRENT=$(cat todo/INDEX.md)

# 2. Modify in memory (example: update status)
UPDATED=$(echo "$CURRENT" | sed "s/| ${TICKET_ID} | ready/| ${TICKET_ID} | in-progress/")

# 3. Write to temp file
echo "$UPDATED" > todo/INDEX.md.tmp

# 4. Atomic rename
mv todo/INDEX.md.tmp todo/INDEX.md
```

This pattern ensures INDEX.md is never in a partially-written state. The `mv` operation is atomic on POSIX systems (macOS, Linux).

## Adding a Ticket Row

When `/jira inbox MT-XXXX` completes, append a row to INDEX.md. If INDEX.md does not exist, create it with the header first.

```bash
TICKET_ID="MT-XXXX"
PRIORITY="high"       # From Jira ticket fields
FETCHED=$(date +%Y-%m-%d)
CONTEXT_READY="yes"   # Based on .state.json ready_for_planning

INDEX_FILE="todo/INDEX.md"

if [ ! -f "$INDEX_FILE" ]; then
    # Create new INDEX.md with header
    cat > "$INDEX_FILE.tmp" << 'HEADER'
# Ticket Inbox Queue

**Last Updated:** TIMESTAMP_PLACEHOLDER

| Ticket | Status | Priority | Fetched | Context Ready |
|--------|--------|----------|---------|---------------|
HEADER
    sed -i '' "s/TIMESTAMP_PLACEHOLDER/$(date -u +"%Y-%m-%dT%H:%M:%SZ")/" "$INDEX_FILE.tmp" 2>/dev/null || \
    sed -i "s/TIMESTAMP_PLACEHOLDER/$(date -u +"%Y-%m-%dT%H:%M:%SZ")/" "$INDEX_FILE.tmp"
    mv "$INDEX_FILE.tmp" "$INDEX_FILE"
fi

# Read current content
CURRENT=$(cat "$INDEX_FILE")

# Find the last table row line number and insert after it
# Append new row after the last | line in the table
LAST_TABLE_LINE=$(grep -n '^|' "$INDEX_FILE" | tail -1 | cut -d: -f1)

{
    head -n "$LAST_TABLE_LINE" "$INDEX_FILE"
    echo "| ${TICKET_ID} | ready | ${PRIORITY} | ${FETCHED} | ${CONTEXT_READY} |"
    tail -n +"$((LAST_TABLE_LINE + 1))" "$INDEX_FILE"
} > "$INDEX_FILE.tmp"

# Update timestamp
sed "s/^\*\*Last Updated:\*\*.*/\*\*Last Updated:\*\* $(date -u +"%Y-%m-%dT%H:%M:%SZ")/" "$INDEX_FILE.tmp" > "$INDEX_FILE.tmp2"
mv "$INDEX_FILE.tmp2" "$INDEX_FILE.tmp"

mv "$INDEX_FILE.tmp" "$INDEX_FILE"
```

## Updating Ticket Status

Atomically change a ticket's status (e.g., `ready` -> `in-progress`):

```bash
TICKET_ID="MT-9550"
OLD_STATUS="ready"
NEW_STATUS="in-progress"
INDEX_FILE="todo/INDEX.md"

# Read -> modify -> write to temp -> atomic rename
sed "s/| ${TICKET_ID} | ${OLD_STATUS} |/| ${TICKET_ID} | ${NEW_STATUS} |/" "$INDEX_FILE" > "$INDEX_FILE.tmp"

# Update timestamp
sed "s/^\*\*Last Updated:\*\*.*/\*\*Last Updated:\*\* $(date -u +"%Y-%m-%dT%H:%M:%SZ")/" "$INDEX_FILE.tmp" > "$INDEX_FILE.tmp2"
mv "$INDEX_FILE.tmp2" "$INDEX_FILE.tmp"

mv "$INDEX_FILE.tmp" "$INDEX_FILE"
```

## Recomputing Summary Line

After any status change, recompute the summary lines at the bottom of INDEX.md:

```bash
INDEX_FILE="todo/INDEX.md"

python3 -c "
import re
from datetime import datetime, timezone

with open('$INDEX_FILE') as f:
    content = f.read()

# Parse table rows
rows = re.findall(r'^\| (MT-\S+)\s+\| (\S+)\s+\| (\S+)\s+\| (\S+)\s+\| (\S+)\s+\|', content, re.MULTILINE)

ready_tickets = [(t, fetched) for t, status, _, fetched, _ in rows if status == 'ready']
in_progress_count = sum(1 for _, status, _, _, _ in rows if status == 'in-progress')

# Find oldest ready
oldest_line = ''
if ready_tickets:
    oldest = min(ready_tickets, key=lambda x: x[1])
    days = (datetime.now(timezone.utc) - datetime.strptime(oldest[1], '%Y-%m-%d').replace(tzinfo=timezone.utc)).days
    oldest_line = f'**Oldest ready:** {oldest[0]} ({days} days)'
else:
    oldest_line = '**Oldest ready:** none'

summary_line = f'**Total ready:** {len(ready_tickets)} | **In progress:** {in_progress_count}'

# Remove old summary lines and append new ones
lines = content.rstrip().split('\n')
# Remove existing summary lines
lines = [l for l in lines if not l.startswith('**Oldest ready:') and not l.startswith('**Total ready:')]

# Remove trailing blank lines
while lines and lines[-1].strip() == '':
    lines.pop()

lines.append('')
lines.append(oldest_line)
lines.append(summary_line)
lines.append('')

with open('${INDEX_FILE}.tmp', 'w') as f:
    f.write('\n'.join(lines))
"

mv "$INDEX_FILE.tmp" "$INDEX_FILE"
```

## Assumptions

- `mv` is atomic on POSIX systems (macOS, Linux). On Windows, use WSL or Git Bash for POSIX semantics.
- INDEX.md is processed sequentially (one agent at a time). No concurrent access requires file locking.
- Ticket IDs follow the pattern `[A-Z]+-\d+` (e.g., MT-9550).

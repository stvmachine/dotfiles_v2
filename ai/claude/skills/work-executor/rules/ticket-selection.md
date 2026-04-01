# Ticket Selection

Pick a ticket from the `todo/INDEX.md` queue for processing. Implements D-01, D-02, D-03.

## Input

- Optional: `TICKET_ID` argument (e.g., from `/work MT-9550`)
- Required: `todo/INDEX.md` must exist (created by `/jira inbox`)

## Output

- `TICKET_ID` variable set for downstream rules
- INDEX.md updated: selected ticket status changed to `in-progress`

## Direct Invocation (Ticket ID Provided)

When work-executor is called with a specific ticket ID (e.g., `/work MT-9550`):

1. **Validate ticket exists in todo/**:
   ```bash
   if [ ! -d "todo/${TICKET_ID}" ]; then
       echo "ERROR: Ticket ${TICKET_ID} not found in todo/. Check the ticket ID and try again."
       exit 1
   fi
   ```

2. **Validate ticket exists in INDEX.md**:
   ```bash
   if ! grep -q "| ${TICKET_ID} |" todo/INDEX.md 2>/dev/null; then
       echo "ERROR: Ticket ${TICKET_ID} not found in INDEX.md. Run '/jira inbox ${TICKET_ID}' first."
       exit 1
   fi
   ```

3. **Check ticket status**:
   ```bash
   CURRENT_STATUS=$(grep "| ${TICKET_ID} |" todo/INDEX.md | awk -F'|' '{print $3}' | xargs)
   if [ "$CURRENT_STATUS" = "in-progress" ]; then
       echo "WARNING: Ticket ${TICKET_ID} is already in-progress. Continuing with it."
   fi
   ```

4. **Update INDEX.md status** to `in-progress` via index-management.md atomic update pattern:
   ```bash
   sed "s/| ${TICKET_ID} | ready |/| ${TICKET_ID} | in-progress |/" todo/INDEX.md > todo/INDEX.md.tmp
   mv todo/INDEX.md.tmp todo/INDEX.md
   ```

5. Skip to downstream rules with `TICKET_ID` set.

## Interactive Selection (No Ticket ID)

When work-executor is called without arguments (e.g., `/work`):

### Step 1: Read INDEX.md

```bash
INDEX_FILE="todo/INDEX.md"

if [ ! -f "$INDEX_FILE" ]; then
    echo "ERROR: No tickets in queue. Run '/jira inbox MT-XXXX' to fetch a Jira ticket first."
    exit 1
fi
```

### Step 2: Filter Ready Tickets

```bash
READY_ROWS=$(grep -E '^\| MT-' "$INDEX_FILE" | grep '| ready |')

if [ -z "$READY_ROWS" ]; then
    echo "All tickets are already in progress. Fetch a new ticket or wait for current work to complete."
    exit 1
fi
```

### Step 3: Sort by Fetched Date (Oldest First)

```bash
# Rows are already in table order. Sort by the Fetched column (column 5) ascending.
SORTED_ROWS=$(echo "$READY_ROWS" | sort -t'|' -k5)
```

### Step 4: Display Full Index Table

Show the complete INDEX.md table to the user so they have full context:

```bash
echo ""
echo "=== Ticket Inbox Queue ==="
echo ""
# Show the full table (including header and all rows)
head -n 1 "$INDEX_FILE"  # Title
echo ""
grep -E '^\|' "$INDEX_FILE"  # Full table with headers
echo ""
# Show summary lines
grep -E '^\*\*' "$INDEX_FILE"
echo ""
```

### Step 5: Present Default and Prompt

```bash
# Get oldest ready ticket as default
OLDEST_TICKET=$(echo "$SORTED_ROWS" | head -1 | awk -F'|' '{print $2}' | xargs)

echo "Press Enter to use default [${OLDEST_TICKET}], or type a ticket ID:"
```

### Step 6: Accept User Input

```bash
read -r USER_INPUT

if [ -z "$USER_INPUT" ]; then
    TICKET_ID="$OLDEST_TICKET"
    echo "Using default: ${TICKET_ID}"
else
    TICKET_ID="$USER_INPUT"
    echo "Selected: ${TICKET_ID}"
fi
```

### Step 7: Validate Selected Ticket

```bash
# Check ticket directory exists
if [ ! -d "todo/${TICKET_ID}" ]; then
    echo "ERROR: Ticket ${TICKET_ID} not found in todo/. Check the ticket ID and try again."
    exit 1
fi

# Check ticket is in INDEX.md with ready status
if ! grep -q "| ${TICKET_ID} | ready |" todo/INDEX.md; then
    echo "ERROR: Ticket ${TICKET_ID} is not in 'ready' status in INDEX.md."
    exit 1
fi
```

### Step 8: Update INDEX.md Status

Use the atomic update pattern from index-management.md:

```bash
# Atomic status update: ready -> in-progress
sed "s/| ${TICKET_ID} | ready |/| ${TICKET_ID} | in-progress |/" todo/INDEX.md > todo/INDEX.md.tmp
mv todo/INDEX.md.tmp todo/INDEX.md
echo "Ticket ${TICKET_ID} marked as in-progress."
```

After updating status, recompute the summary lines using the pattern from index-management.md.

## Error Messages

| Condition | Message |
|-----------|---------|
| INDEX.md missing | `ERROR: No tickets in queue. Run '/jira inbox MT-XXXX' to fetch a Jira ticket first.` |
| No ready tickets | `All tickets are already in progress. Fetch a new ticket or wait for current work to complete.` |
| Ticket dir missing | `ERROR: Ticket {TICKET_ID} not found in todo/. Check the ticket ID and try again.` |
| Ticket not in INDEX | `ERROR: Ticket {TICKET_ID} not found in INDEX.md. Run '/jira inbox {TICKET_ID}' first.` |

## Complete Selection Flow

```
1. Check INDEX.md exists          -> D-03 error if missing
2. Filter rows: Status = ready    -> "All in progress" if none
3. Sort by Fetched ascending      -> Oldest first
4. Display full table to user
5. Show default: oldest ready
6. Prompt: "Press Enter to use default [MT-XXXX], or type a ticket ID:"
7. Accept input or use default
8. Validate ticket exists in todo/
9. Update INDEX.md status -> in-progress (via index-management.md atomic update)
10. Set TICKET_ID for downstream rules
```

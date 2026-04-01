# Ticket Update (Re-fetch) Rule

Logic for updating an existing ticket in todo/ by re-fetching all content. Per D-04, all content is overwritten — no merging, no diff.

## Section 1: Pre-flight Checks

Before re-fetching, verify the ticket directory exists.

```bash
TICKET_ID="MT-XXXX"  # From user input
TICKET_DIR="./todo/$TICKET_ID"

# Check if ticket directory exists
if [ ! -d "$TICKET_DIR" ]; then
    echo "ERROR: Ticket $TICKET_ID not found in todo/" >&2
    echo "Use '/jira inbox $TICKET_ID' to fetch it first." >&2
    exit 1
fi

echo "Found existing ticket: $TICKET_DIR"
echo "Preparing to re-fetch all content..."
```

If the directory does NOT exist, inform the user to use `/jira inbox $TICKET_ID` to fetch it first.

## Section 2: Overwrite Strategy (per D-04)

Per decision D-04, re-fetching uses a clean overwrite strategy — delete all existing content before re-fetching to ensure no stale data remains.

```bash
TICKET_DIR="./todo/$TICKET_ID"

# Remove existing content (per D-04: overwrite all, no merging)
echo "Removing old content..."
rm -f "$TICKET_DIR/TICKET_DESCRIPTION.md"
rm -rf "$TICKET_DIR/assets/"
rm -rf "$TICKET_DIR/context/"
rm -f "$TICKET_DIR/.state.json"

# Recreate directory structure
mkdir -p "$TICKET_DIR/assets"
mkdir -p "$TICKET_DIR/context"

echo "Directory cleaned and ready for re-fetch"
```

**Why this approach:**
- Ensures no stale attachments from previous fetch
- Removes outdated context files (Confluence/Figma/GitHub may have changed)
- Cleans up state file to reflect fresh fetch status
- Simple and predictable — complete replacement

**Note for users:** If you have persistent notes or planning documents about this ticket, keep them OUTSIDE the `todo/MT-XXXX/` directory (e.g., in `.planning/`, a separate notes file, or a project-specific planning folder). The inbox workflow owns the `todo/MT-XXXX/` directory exclusively.

## Section 3: Re-fetch

After cleaning the directory, delegate to the fetch rule to perform the actual re-fetch.

```bash
# Follow the exact same process as initial fetch
# See rules/fetch.md for complete implementation
```

**Re-fetch process includes:**
1. Jira ticket fetch with MCP validation and retry (rules/mcp-utils.md patterns)
2. TICKET_DESCRIPTION.md creation with full metadata and references
3. Attachment download to assets/ directory
4. Link extraction and routing to downstream rules:
   - Confluence links → rules/confluence.md
   - Figma links → rules/figma-integration.md
   - GitHub links → rules/github.md
5. State file creation via rules/state-file.md

All steps follow the same patterns and validation as the initial fetch. The only difference is that we've cleaned the directory first.

## Section 4: Completion

After re-fetch completes, display what was updated.

```bash
# Count files in each directory
ASSET_COUNT=$(ls -1 "$TICKET_DIR/assets/" 2>/dev/null | wc -l | tr -d ' ')
CONTEXT_COUNT=$(ls -1 "$TICKET_DIR/context/" 2>/dev/null | wc -l | tr -d ' ')

echo ""
echo "✓ Ticket updated: todo/$TICKET_ID/"
echo "  • TICKET_DESCRIPTION.md (overwritten)"
echo "  • assets/ (re-downloaded: $ASSET_COUNT files)"
echo "  • context/ (re-fetched: $CONTEXT_COUNT files)"
echo "  • .state.json (recreated)"
echo ""
echo "All content has been refreshed from Jira and linked sources."
```

**When to use update:**
- Ticket description or acceptance criteria changed in Jira
- New attachments added or old ones removed
- Linked Confluence/Figma/GitHub content updated
- Want to ensure local copy matches current Jira state

**Update frequency:**
- Before starting work on a ticket (ensure latest requirements)
- After significant discussion in Jira comments
- When notified of design or spec changes
- Generally: when in doubt, re-fetch to stay synchronized

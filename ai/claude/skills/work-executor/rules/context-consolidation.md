# Context Consolidation

Consolidate ticket data from `todo/{TICKET_ID}/` into a GSD phase CONTEXT.md document. Implements PLAN-02.

## Input

- `TICKET_ID` variable (set by ticket-selection.md)
- `todo/{TICKET_ID}/` directory with TICKET_DESCRIPTION.md and .state.json

## Output

- `PHASE_DIR` variable: path to the new GSD phase directory
- `PHASE_NUM` variable: the phase number assigned
- `{PHASE_NUM}-CONTEXT.md` file in the phase directory

## Pre-flight: Validate Ticket Directory

```bash
if [ ! -d "todo/${TICKET_ID}" ]; then
    echo "ERROR: Ticket ${TICKET_ID} not found in todo/. Check the ticket ID and try again."
    exit 1
fi

if [ ! -f "todo/${TICKET_ID}/TICKET_DESCRIPTION.md" ]; then
    echo "ERROR: TICKET_DESCRIPTION.md missing for ${TICKET_ID}. Re-fetch with '/jira inbox ${TICKET_ID}'."
    exit 1
fi
```

## Phase Directory Creation

Create `.planning/phases/{PHASE_NUM}-{TICKET_ID}-{slug}/` where:

### Determine Next Phase Number

Scan existing `.planning/phases/` directories to find the next available phase number:

```bash
# Get highest existing phase number
HIGHEST=$(ls .planning/phases/ 2>/dev/null | grep -oE '^\d+' | sort -n | tail -1)

if [ -z "$HIGHEST" ]; then
    PHASE_NUM="01"
else
    PHASE_NUM=$(printf "%02d" $((10#$HIGHEST + 1)))
fi
```

### Derive Slug from Ticket Summary

Generate a URL-safe slug from the first line of TICKET_DESCRIPTION.md:

```bash
SUMMARY=$(head -1 "todo/${TICKET_ID}/TICKET_DESCRIPTION.md" | sed 's/^#*\s*//' | sed 's/\*\*//g')
SLUG=$(echo "$SUMMARY" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9 ]//g' | sed 's/ /-/g' | cut -c1-40)
```

Example: "MT-9550: Add user authentication flow" -> "mt9550-add-user-authentication-flow"

### Create the Directory

```bash
PHASE_DIR=".planning/phases/${PHASE_NUM}-${TICKET_ID}-${SLUG}"

if [ -d "$PHASE_DIR" ]; then
    echo "ERROR: Phase directory already exists at ${PHASE_DIR}. Remove it or choose a different ticket."
    exit 1
fi

mkdir -p "$PHASE_DIR"
echo "Created phase directory: $PHASE_DIR"
```

## CONTEXT.md Generation

Create `{PHASE_NUM}-CONTEXT.md` in the phase directory with consolidated ticket data.

```bash
CONTEXT_FILE="${PHASE_DIR}/${PHASE_NUM}-CONTEXT.md"
TICKET_DIR="todo/${TICKET_ID}"
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# Extract summary from first line
TICKET_SUMMARY=$(head -1 "${TICKET_DIR}/TICKET_DESCRIPTION.md" | sed 's/^#*\s*//')
```

### Generate Context Document via Python

Use Python to read .state.json and construct the full CONTEXT.md:

```python
python3 << 'PYEOF' > "${CONTEXT_FILE}"
import json
import os
import glob
from datetime import datetime, timezone

ticket_id = os.environ.get('TICKET_ID', '${TICKET_ID}')
ticket_dir = os.environ.get('TICKET_DIR', '${TICKET_DIR}')
timestamp = os.environ.get('TIMESTAMP', '${TIMESTAMP}')

# Read ticket summary
with open(f'{ticket_dir}/TICKET_DESCRIPTION.md') as f:
    description_content = f.read()
    summary_line = description_content.split('\n')[0].lstrip('#').strip()

# Read state file
state = {}
state_file = f'{ticket_dir}/.state.json'
if os.path.exists(state_file):
    with open(state_file) as f:
        state = json.load(f)

# Build CONTEXT.md
print(f'# Phase Context: {summary_line}')
print()
print(f'**Ticket:** {ticket_id}')
print(f'**Source:** {ticket_dir}/')
print(f'**Generated:** {timestamp}')
print(f'**Status:** Ready for GSD planning')
print()
print('## Ticket Description')
print()
print(description_content)
print()
print('## Available Context Sources')
print()

sources = state.get('sources', {})
for source_name, data in sources.items():
    status = data.get('status', 'unknown')
    print(f'### {source_name.title()}')
    print(f'**Status:** {status}')

    if status == 'success':
        files = data.get('files', []) or []
        single_file = data.get('file')
        if single_file:
            files = [single_file]
        if files:
            print('**Files:**')
            for file_path in files:
                print(f'- {file_path}')
    elif status == 'failed':
        error = data.get('error', 'Unknown error')
        print(f'**Error:** {error}')
    # skipped sources just show status
    print()

# List attachments
print('## Attachments')
print()
assets_dir = f'{ticket_dir}/assets'
if os.path.exists(assets_dir):
    assets = sorted(os.listdir(assets_dir))
    assets = [a for a in assets if not a.startswith('.')]
    if assets:
        for asset in assets:
            asset_path = f'{ticket_dir}/assets/{asset}'
            size_kb = os.path.getsize(asset_path) / 1024
            print(f'- [{asset}]({asset_path}) ({size_kb:.0f} KB)')
    else:
        print('No attachments found.')
else:
    print('No assets directory.')
print()

print('## Implementation Notes')
print()
print('- This is an automated context consolidation from the ticket inbox')
print('- GSD discuss phase will use this as input for planning')
print('- All paths are relative to project root')
PYEOF
```

### CONTEXT.md Structure

The generated file follows this structure:

```markdown
# Phase Context: {Ticket Summary}

**Ticket:** {TICKET_ID}
**Source:** todo/{TICKET_ID}/
**Generated:** {ISO 8601 timestamp}
**Status:** Ready for GSD planning

## Ticket Description

{Full content of TICKET_DESCRIPTION.md}

## Available Context Sources

{For each source in .state.json where status=success:}
### {Source Name}
**Status:** {status}
**Files:**
- {list of files with paths relative to todo/{TICKET_ID}/}

{For each source where status=failed or skipped:}
### {Source Name}
**Status:** {status} ({error message if failed})

## Attachments

{List all files in todo/{TICKET_ID}/assets/ with paths}

## Implementation Notes

- This is an automated context consolidation from the ticket inbox
- GSD discuss phase will use this as input for planning
- All paths are relative to project root
```

## Completion

After CONTEXT.md is created:

```bash
echo "Context consolidated: ${CONTEXT_FILE}"
echo "  Phase directory: ${PHASE_DIR}"
echo "  Phase number: ${PHASE_NUM}"
echo ""
echo "Ready for GSD orchestration (rules/gsd-orchestration.md)"
```

Set `PHASE_DIR` and `PHASE_NUM` variables for downstream rules (gsd-orchestration.md, branch-management.md).

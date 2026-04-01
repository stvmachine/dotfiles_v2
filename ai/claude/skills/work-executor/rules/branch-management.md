# Branch Management

Create a feature branch for the selected ticket. Implements EXEC-01.

## Input

- `TICKET_ID` variable (set by ticket-selection.md)
- `todo/{TICKET_ID}/TICKET_DESCRIPTION.md` for slug derivation

## Output

- `BRANCH_NAME` variable for downstream rules
- Working directory on the new feature branch

## Branch Naming Convention

Pattern: `feature/{TICKET_ID}-{slug}`

Where:
- `TICKET_ID`: e.g., MT-9550
- `slug`: Lowercase summary, hyphens for spaces, special chars stripped, max 40 characters

Example: `feature/MT-9550-add-user-authentication-flow`

## Slug Generation

```bash
SUMMARY=$(head -1 todo/${TICKET_ID}/TICKET_DESCRIPTION.md | sed 's/^#*\s*//' | sed 's/\*\*//g')
SLUG=$(echo "$SUMMARY" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9 ]//g' | sed 's/ /-/g' | cut -c1-40)
BRANCH_NAME="feature/${TICKET_ID}-${SLUG}"
```

## Pre-flight Checks

### 1. Clean Working Directory

Ensure no uncommitted changes that could conflict with branch creation:

```bash
if [ -n "$(git status --porcelain)" ]; then
    echo "WARNING: Working directory has uncommitted changes."
    echo ""
    git status --short
    echo ""
    echo "Please stash or commit your changes before proceeding."
    echo "  git stash        # Temporarily shelve changes"
    echo "  git stash pop    # Restore after switching branches"
    exit 1
fi
```

### 2. Check for Existing Branch

If a branch for this ticket already exists, switch to it instead of creating a new one:

```bash
EXISTING_BRANCH=$(git branch --list "feature/${TICKET_ID}-*" | head -1 | xargs)

if [ -n "$EXISTING_BRANCH" ]; then
    echo "WARNING: Branch ${EXISTING_BRANCH} already exists. Switching to existing branch."
    git checkout "$EXISTING_BRANCH"
    BRANCH_NAME="$EXISTING_BRANCH"
else
    # Create new branch
    git checkout -b "$BRANCH_NAME"
    echo "Created branch: $BRANCH_NAME"
fi
```

## Branch Creation

```bash
# Full branch creation flow
SUMMARY=$(head -1 todo/${TICKET_ID}/TICKET_DESCRIPTION.md | sed 's/^#*\s*//' | sed 's/\*\*//g')
SLUG=$(echo "$SUMMARY" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9 ]//g' | sed 's/ /-/g' | cut -c1-40)
BRANCH_NAME="feature/${TICKET_ID}-${SLUG}"

# Pre-flight: clean working directory
if [ -n "$(git status --porcelain)" ]; then
    echo "WARNING: Working directory has uncommitted changes."
    echo "Please stash or commit your changes before proceeding."
    exit 1
fi

# Pre-flight: check existing branch
EXISTING=$(git branch --list "feature/${TICKET_ID}-*" | head -1 | xargs)

if [ -n "$EXISTING" ]; then
    echo "WARNING: Branch ${EXISTING} already exists. Switching to existing branch."
    git checkout "$EXISTING"
    BRANCH_NAME="$EXISTING"
else
    git checkout -b "$BRANCH_NAME"
    echo "Created branch: $BRANCH_NAME"
fi

echo "On branch: $BRANCH_NAME"
```

## Important: No Push

Per D-05, no external-facing actions happen until the human checkpoint at the very end of the workflow. The branch stays local until the user explicitly approves pushing.

Do NOT run `git push` in this rule. The push happens only after:
1. Implementation is complete
2. Tests pass
3. Lint passes
4. Human checkpoint approved

See `rules/human-checkpoint.md` for the push step.

## Completion

After branch creation/checkout:

```bash
echo ""
echo "Branch ready: $BRANCH_NAME"
echo "  Ticket: $TICKET_ID"
echo "  Status: Local only (push deferred to human checkpoint)"
echo ""
echo "Proceeding to context consolidation (rules/context-consolidation.md)"
```

Set `BRANCH_NAME` for downstream rules.

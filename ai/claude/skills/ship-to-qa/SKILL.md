---
name: ship-to-qa
description: Ship completed work to QA — create GitHub PR, commit staged changes, transition Jira ticket to QA, link the PR on the ticket, update beads task, and narrate to worktale. Use when the user says "ship", "ship to QA", "send to QA", "create PR and update Jira", or wants to finalize a feature branch for review. Combines commit, GitHub PR, Jira, beads, and worktale workflows into a single command.
allowed-tools: Bash(git *), Bash(gh *), Bash(curl *), Bash(python3 *), Bash(bd *), mcp__mcp-atlassian__*, mcp__github__*
---

# Ship to QA

Single command to ship a feature branch: commit, create PR, transition Jira to QA, link the PR, and narrate to worktale.

## Dependencies

This skill orchestrates five other skills — invoke them, don't duplicate their logic:
- **`/commit`** — used in Step 3 for creating properly formatted commits
- **`/jira`** — used in Steps 5-6 for Jira transitions and linking (follow its patterns for MCP usage, comment formatting, and credential extraction)
- **`/jira-markup`** — used in Steps 5-6 for Jira transitions and linking (follow its patterns for MCP usage, comment formatting, and credential extraction)
- **`beads`** — used throughout for persistent task tracking and multi-agent coordination
- **`worktale`** — used throughout for session narration and capturing work context
## Pipeline Mode

When invoked from the work executor's `rules/integration.md` (pipeline mode), the following overrides apply. Per D-02, this mode is for agent-to-agent invocation where no human is available to answer prompts.

**Pipeline mode is active when:** The invoking context provides `TICKET_ID`, `BRANCH_NAME`, `BASE_BRANCH`, and `PR_BODY_FILE` variables directly (passed from integration.md). The presence of `PR_BODY_FILE` is the signal that pipeline mode is active.

**Pipeline mode overrides by step:**
- **Step 1 (Gather Context):** Skip user confirmation of ticket ID. Use `TICKET_ID` directly. Skip `git status`/`git diff --stat` display (executor already showed this at checkpoint). Use `BASE_BRANCH` directly instead of inferring. Still execute the "Mark ticket as shipped in todo/" substep.
- **Step 2 (Ensure Feature Branch):** Skip entirely — branch already exists and is checked out from Phase 2.
- **Step 3 (Commit):** Skip entirely — code is already committed by Phase 2. Per D-02, skip commit step.
- **Step 4 (Create PR):** Push branch with `git push -u origin HEAD`. Check for existing PR with `gh pr view --json url,title 2>/dev/null`. If PR exists, reuse it without asking (per D-02). If no PR, create with `gh pr create --base "$BASE_BRANCH" --title "<generated title>" --body-file "$PR_BODY_FILE"`. The PR title should still follow gitmoji conventional commit format. Use `--body-file` instead of `--body` to avoid shell escaping issues.
- **Step 5 (Transition Jira):** Get transitions via `mcp__mcp-atlassian__jira_get_transitions`. Match transition name containing "QA" or "Review" (case-insensitive). Per D-02: if zero matches, FAIL with error "No QA/Review transition found for {TICKET_ID}". If 2+ matches, FAIL with error "Ambiguous QA transitions found: {list names}. Cannot auto-select in pipeline mode." Do NOT prompt the user.
- **Step 6 (Link PR):** Execute normally — no changes needed for pipeline mode.
- **Step 7 (Summary):** Execute normally — no changes needed for pipeline mode.

## Workflow

### Step 1: Gather Context & Identify Ticket

> In pipeline mode: skip to substep 4 (resolve ticket ID) using provided TICKET_ID, then execute only the "Mark ticket as shipped in todo/" substep. Skip substeps 1-3 and 5-7.

1. Run `git branch --show-current` to get current branch
2. Extract Jira ticket ID from branch name using pattern `([A-Z][A-Z0-9]+-\d+)`
3. Check for `todo/` directories: `ls todo/` to find any `MT-XXXX` folders
4. **Resolve the ticket ID:**
   - If a ticket ID was provided as argument, use it
   - If only one `todo/MT-XXXX` folder exists, ask the user to confirm: "Shipping MT-XXXX — correct?"
   - If multiple `todo/MT-XXXX` folders exist, list them and ask the user which one
   - If no `todo/` folders but branch has a ticket ID, use the branch ticket ID
   - If nothing found, ask the user for the ticket ID
5. Run `git status` and `git diff --stat` to see what's pending
6. Run `git log --oneline master..HEAD` to see all commits on this branch
7. Determine the base branch — use `master` unless the branch name starts with `release/` (then find the parent release branch)
8. **Mark ticket as shipped in todo/**: If `todo/<TICKET-ID>/` exists, update `todo/<TICKET-ID>/TICKET_DESCRIPTION.md` — change the `**Status**` field in the metadata table to `QA` and append a "Shipped" section at the bottom:
   ```markdown
   ## Shipped
   - **PR**: <PR URL>
   - **Date**: <today's date>
   - **Branch**: <branch name>
   ```

### Step 2: Ensure Feature Branch

> In pipeline mode: skip this step entirely.

**NEVER push directly to protected branches:** `master`, `main`, `dev`, or `release/*`.

1. Check if the current branch is a protected branch (matches `master`, `main`, `dev`, or `release/*`)
2. If on a protected branch, create a feature branch and move commits:
   - Determine branch prefix from commit type: `feat/`, `fix/`, `refactor/`, `chore/`, etc.
   - Build branch name: `<prefix>/<TICKET-ID>_<short_description>` (e.g. `feat/MT-9561_filter_coordinator_roles`)
   - Count commits ahead of origin: `git rev-list --count origin/<current-branch>..HEAD`
   - If there are unpushed commits on the protected branch:
     ```bash
     # Save the current position
     COMMIT_COUNT=$(git rev-list --count origin/<protected-branch>..HEAD)
     # Create the feature branch at current position
     git checkout -b <feature-branch>
     # Reset the protected branch back to origin
     git branch -f <protected-branch> origin/<protected-branch>
     ```
   - If there are no unpushed commits, just create and switch: `git checkout -b <feature-branch>`
3. If already on a feature branch (not protected), continue as-is

### Step 3: Commit (if needed)

> In pipeline mode: skip this step entirely.

If there are uncommitted changes, invoke the `/commit` skill with these constraints:
- Do NOT commit files that are local config (e.g. `values.js` with local URLs, `.env`, credentials)
- NEVER stage or commit anything inside the `todo/` directory — it is local working context, not source code
- Ask the user what to include if unclear

If working tree is clean, skip to Step 4.

### Step 4: Create GitHub PR

> In pipeline mode: use PR_BODY_FILE with --body-file flag instead of inline --body. Reuse existing PR template if exists on the repository without asking.

Try `gh` CLI first. If `gh` is not available or fails, fall back to the GitHub MCP tools.

**Check for PR Template:**
Before creating a PR, check if the repository has a pull request template:
1. Look for `.github/pull_request_template.md` in the repo
2. If it exists, use its structure for the PR body
3. If no template exists, use the default format below

**Option A — gh CLI (preferred):**
1. Check if a PR already exists: `gh pr view --json url,title 2>/dev/null`
2. If PR exists, show it and skip to Step 5
3. If no PR, push the branch: `git push -u origin HEAD`
4. Create the PR with appropriate body:

**If PR template exists (e.g., `.github/pull_request_template.md`):**
- Read the template file and populate its sections
- Common sections to fill: Summary, Changes, Screenshots, Testing, Jira Ticket

**If NO PR template exists, use this default format:**
```markdown
## Summary
<!-- Brief description of what this PR does and why -->

## Description
<!-- Optional: Detailed explanation of changes -->

## JIRA Ticket
<!-- Link to the Jira ticket -->
[TICKET-ID](https://<jira-domain>/browse/TICKET-ID)

## ACs
<!-- Acceptance Criteria from the ticket -->
- [ ] <AC 1>
- [ ] <AC 2>
```

**Example gh command:**
```bash
gh pr create --base <base-branch> --title "<gitmoji> <type>(<scope>): <short description>" --body "$(cat <<'EOF'
## Summary
<brief description>

## Description
<detailed description>

## JIRA Ticket
[TICKET-ID](https://nimblic.atlassian.net/browse/TICKET-ID)

## ACs
- [ ] <acceptance criteria from ticket, if available>
EOF
)"
```

**Option B — GitHub MCP (fallback if gh fails):**
1. Push the branch first: `git push -u origin HEAD`
2. Get repo owner/name from: `git remote get-url origin`
3. Check for existing PR: `mcp__github__list_pull_requests` with head=`<branch>` and base=`<base-branch>`
4. If no PR, create one: `mcp__github__create_pull_request` with title, body, head, and base

**PR content rules:**
- PR title follows the same gitmoji conventional commit format as commits
- If a `todo/<TICKET-ID>/TICKET_DESCRIPTION.md` exists, read it for acceptance criteria to populate the test plan
- Base branch: use `master` by default, or the release branch if on a release/* sub-branch
- Respect the repository's PR template structure if one exists

### Step 5: Transition Jira Ticket to QA

> In pipeline mode: fail hard on zero or ambiguous matches instead of asking user. See Pipeline Mode section above.

Use the `/jira` skill's transition workflow:
1. Get available transitions for the ticket
2. Find the transition that moves to QA (look for names containing "QA", "Ready for QA", "In QA", "Review", or similar)
3. If ambiguous, show options and ask the user
4. Execute the transition

### Step 6: Link PR on Jira Ticket and Update Beads

Use the `/jira-markup` and `/jira` skill's link/comment workflow to post the PR link on the ticket. Follow its comment formatting rules (Jira wiki markup via curl, NOT the MCP comment tool). The comment should include:
- PR title and URL
- Branch name
- Base branch

**Also update beads task:**
1. Find beads task by searching for `[$TICKET_ID]` in title
2. Update task body with PR link
3. Update status to "in_review"

```bash
# Find beads task for this ticket
BEADS_ID=$(bd list --json | python3 -c "
import json, sys, re
tasks = json.load(sys.stdin)
for task in tasks:
    if re.search(r'\[$TICKET_ID\]', task.get('title', '')):
        print(task['id'])
        break
")

if [ -n "$BEADS_ID" ]; then
    # Append PR link to task body
    bd update "$BEADS_ID" --body-append "

## GitHub PRs
- [$PR_TITLE]($PR_URL) - $(date -u +"%Y-%m-%dT%H:%M:%SZ")
"

    # Update status
    bd update "$BEADS_ID" --status "in_review"

    echo "Updated beads task: $BEADS_ID"
fi
```

### Step 7: Archive Ticket (Optional)

After successful ship-to-qa, optionally archive the ticket to centralized storage:

```bash
# Move from local working cache to centralized archive
LOCAL_DIR="./todo/$TICKET_ID"
CENTRAL_DIR="$HOME/.medtasker-tickets/$TICKET_ID"

if [ -d "$LOCAL_DIR" ]; then
    # Ensure central directory exists
    mkdir -p "$CENTRAL_DIR"

    # Copy all content to central (if not already there)
    cp -r "$LOCAL_DIR/"* "$CENTRAL_DIR/" 2>/dev/null || true

    # Remove local directory
    rm -rf "$LOCAL_DIR"

    echo "Archived $TICKET_ID to ~/.medtasker-tickets/"
fi
```

### Step 8: Narrate to Worktale

After successful completion, narrate the outcome to worktale:
```bash
worktale note "Shipped <TICKET-ID> to QA — PR created, Jira transitioned, beads updated"
```

If any step failed, narrate the failure:
```bash
worktale note "QA handoff for <TICKET-ID> blocked — <failure reason>"
```

### Step 9: Summary

Display a summary:
```
Shipped <TICKET-ID> to QA:
  PR: <PR URL>
  Jira: transitioned to <new status>
  Comment: linked PR on ticket
  Beads: updated task <BEADS_ID> with PR link
  Archive: moved to ~/.medtasker-tickets/<TICKET-ID>/
  Worktale: narration complete
```

## Enriching Existing PR Descriptions

When asked to "enrich" or update a PR description:

1. **Fetch PR details** using `gh pr view <pr-number> --json title,body,author,state,url,createdAt,updatedAt,headRefName,baseRefName,commits,files`
2. **Analyze commits** to understand the changes:
   - Use `git log <base>..<head> --format="%s" --no-merges` to get commit messages
   - Use `git diff <base>..<head> --stat` to get file change statistics
3. **Build rich description** including:
   - Overview table (Author, Branch, Status, URL, Created/Updated dates)
   - Summary of what the PR does
   - Detailed changes section with commit breakdown
   - Files changed statistics
   - Testing notes
4. **Update PR** using `gh pr edit <pr-number> --body "<new description>"`

**Authentication note:** If `gh auth status` shows invalid credentials, export a fresh token:
```bash
export GH_TOKEN=<fresh_token>
```

## Invocation Patterns

- `/ship-to-qa` — run full workflow, auto-detect ticket from branch
- `/ship-to-qa MT-1234` — run full workflow for specific ticket
- If already committed and PR exists, skip to Jira steps
- `enrich PR description of <pr-url>` — update an existing PR with a rich description

## Error Handling

- If `gh` CLI not authenticated: tell user to run `gh auth login`
- If Jira MCP not connected: tell user to check `~/.claude/mcp.json` credentials
- If no QA transition available: show available transitions and ask user which to use
- If PR creation fails (e.g. no upstream): push first, then retry
- If in pipeline mode and transition is ambiguous: FAIL with descriptive error (do not prompt)
- If in pipeline mode and PR creation fails: FAIL with error (do not retry interactively)
- If beads is not initialized: warn but continue (beads integration is optional)
- If beads task not found: warn but continue (ticket may not have been fetched via /jira inbox)

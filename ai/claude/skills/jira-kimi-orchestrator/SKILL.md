---
name: jira-kimi-orchestrator
description: Orchestrate Jira ticket workflow with automated planning, kimi-cli execution, and project management. Use when user wants to start work on a Jira ticket (MT project), automatically fetch ticket details, gather Confluence/Figma references, create GitHub branch, plan work using GSD methodology, delegate execution to kimi-cli, and manage the code review process. Triggers: "start work on MT-XXXX", "work on Jira ticket", "process PR for MT-XXXX", "orchestrate ticket workflow", "auto-work on ticket".
---

# Jira-Kimi Orchestrator

Orchestrates complete workflow from Jira ticket to code completion: fetch ticket details, gather context from Confluence/Figma, plan using GSD, delegate to kimi-cli, and manage review.

## Prerequisites

- MCP Atlassian configured (Jira + Confluence)
- MCP Figma configured (optional, for design files)
- GitHub CLI (`gh`) authenticated
- GSD (get-shit-done) installed: `npx get-shit-done-cc@latest --claude --global`
- kimi-cli installed and configured

## Workflow

### Phase 1: Fetch Jira Ticket

Fetch the ticket details using mcp-atlassian:

```
Use tool: jira_get_issue
issue_key: "MT-XXXX"
fields: "*all"
expand: "renderedFields,changelog"
comment_limit: 20
```

Extract from ticket:
- Summary, description, acceptance criteria
- Labels, priority, assignee, reporter
- Linked issues (Epic, blocks, relates to)
- Attachments
- Comments with relevant context
- Custom fields (if any)

### Phase 2: Gather Context

#### Confluence Links

Scan ticket description, comments, and custom fields for Confluence URLs:
- Pattern: `https://medtasker.atlassian.net/wiki/spaces/*/pages/*`
- Pattern: `https://medtasker.atlassian.net/wiki/spaces/*/overview`

For each found link, extract the page ID and fetch:

```
Use tool: confluence_get_page
page_id: "PAGE_ID"
convert_to_markdown: true
include_metadata: true
```

Also fetch child pages if relevant:

```
Use tool: confluence_get_page_children
parent_id: "PAGE_ID"
include_content: true
convert_to_markdown: true
```

#### Figma Links

Scan for Figma references:
- Pattern: `https://www.figma.com/file/FILE_KEY/`
- Pattern: `https://www.figma.com/design/FILE_KEY/`

Extract file key and fetch design data:

```
Use tool: get_figma_data
fileKey: "FILE_KEY"
```

If specific frames/components are needed, download as images:

```
Use tool: download_figma_images
fileKey: "FILE_KEY"
localPath: ".planning/assets/figma"
nodes: [{ nodeId: "NODE_ID", fileName: "design-element.png" }]
```

#### GitHub Context

Check for linked PRs:

```bash
gh pr list --search "MT-XXXX" --state open
gh pr view PR_NUMBER --json title,body,headRefName,baseRefName
```

### Phase 3: Create Branch

Create a feature branch for the work:

```bash
# Ensure on main/master
gh repo view --json defaultBranchRef

# Create and checkout branch
BRANCH_NAME="feature/MT-XXXX-$(echo "$TICKET_SUMMARY" | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | cut -c1-50)"
git checkout -b "$BRANCH_NAME"

# Push branch to remote
git push -u origin "$BRANCH_NAME"
```

### Phase 4: Initialize GSD

If not already using GSD in this repo, initialize:

```bash
# Check if .planning exists
if [ ! -d ".planning" ]; then
    /gsd:new-project --auto
fi
```

Create a new phase for this ticket:

```bash
/gsd:add-phase
# Input: "MT-XXXX: $TICKET_SUMMARY"
```

### Phase 5: Create Context Document

Create comprehensive context document for planning:

**File**: `.planning/MT-XXXX-CONTEXT.md`

```markdown
# MT-XXXX Context

## Jira Ticket
- **Key**: MT-XXXX
- **Summary**: [Ticket summary]
- **Priority**: [Priority]
- **Labels**: [Labels]
- **Assignee**: [Assignee]
- **Reporter**: [Reporter]

## Description
[Full ticket description]

## Acceptance Criteria
[List acceptance criteria]

## Confluence References
[Links + summaries of relevant Confluence pages]

## Figma References
[Links + descriptions of design files]

## Linked Issues
- **Epic**: [Epic link if any]
- **Blocks**: [Blocked issues]
- **Related**: [Related issues]

## GitHub
- **Branch**: feature/MT-XXXX-...
- **Base**: main

## Technical Notes
[Any technical details from comments or analysis]
```

### Phase 6: Plan with GSD

Run GSD planning phase:

```bash
/gsd:discuss-phase [N]
# Review MT-XXXX-CONTEXT.md with user
# Confirm approach

/gsd:plan-phase [N]
# Generates: {phase_num}-RESEARCH.md, {phase_num}-{N}-PLAN.md files
```

### Phase 7: Create Kimi Plan

Convert GSD plans to kimi-cli compatible format.

Two options:

**Option A: Simple Plan (for direct kimi execution)**
**Location**: `~/.kimi/plans/MT-XXXX.md`

```markdown
# Plan: MT-XXXX - [Summary]

## Overview
[What needs to be done]

## Context from Jira
[Key requirements and acceptance criteria]

## Confluence Context
[Relevant documentation summaries]

## Design References
[Figma file paths if downloaded]

## Files to Modify
[List of files based on GSD plan]

## Implementation Steps

### Step 1: [Name]
**Files**: `path/to/file1.js`, `path/to/file2.js`
**Action**:
[Detailed action description]

**Verification**:
[How to verify this step]

### Step 2: [Name]
...

## Testing
[Testing requirements from ticket]

## Acceptance Criteria Checklist
- [ ] Criterion 1
- [ ] Criterion 2
...

## Git Commands
```bash
# When done:
git add .
git commit -m "feat(MT-XXXX): [description]"
git push origin feature/MT-XXXX-...
```
```

**Option B: GSD Plan (for GSD-Kimi integration)**

If user has `gsd-kimi` installed (`~/.kimi/skills/gsd-kimi/`):

```bash
# Use GSD-Kimi for structured planning
gsd discuss-phase 1
gsd plan-phase 1
# Creates: .planning/phase-1-MT-XXXX/1-1-PLAN.md
```

Then execute with:
```bash
kimi --agent-file ~/.kimi/skills/gsd-kimi/gsd-agent.yaml \
     --yolo \
     --prompt "Execute all plans in .planning/phase-1-MT-XXXX/"
```

### Phase 8: Execute with Kimi

Start kimi-cli with the plan:

```bash
cd [project-directory]
kimi --yolo --prompt "Execute the plan in ~/.kimi/plans/MT-XXXX.md. Work through each step systematically. When complete, run the git commands to commit and push. Report back success/failure."
```

Or for background execution:

```bash
kimi --yolo --print --prompt "Execute plan in ~/.kimi/plans/MT-XXXX.md" > ~/.kimi/logs/MT-XXXX.log 2>&1
echo $?
```

### Phase 9: Update Jira Ticket

After kimi completes, update the ticket:

```
Use tool: jira_add_comment
issue_key: "MT-XXXX"
body: |
  ## Development Update
  
  **Status**: In Progress → In Review
  
  **Branch**: feature/MT-XXXX-[description]
  
  **Changes**:
  - [Summary of changes made]
  
  **Ready for Review**: [Link to PR if created]
```

Transition ticket status:

```
Use tool: jira_get_transitions
issue_key: "MT-XXXX"

Use tool: jira_transition_issue
issue_key: "MT-XXXX"
transition_id: "[ID for 'In Review' or 'Code Review']"
comment: "Development completed. Ready for code review."
```

### Phase 10: Code Review (Project Manager Mode)

Switch to Project Manager role:

1. **Fetch the PR**:
```bash
gh pr view MT-XXXX --json title,body,files,commits
gh pr diff MT-XXXX
```

2. **Review Checklist**:
   - Code follows project conventions
   - Acceptance criteria met
   - Tests included/updated
   - No breaking changes (unless expected)
   - Documentation updated
   - Design matches Figma (if applicable)

3. **Comment on PR**:
```bash
gh pr comment MT-XXXX --body "[Review feedback]"
```

4. **Approve/Request Changes**:
```bash
gh pr review MT-XXXX --approve --body "LGTM"
# or
gh pr review MT-XXXX --request-changes --body "[Issues to fix]"
```

5. **If approved, merge**:
```bash
gh pr merge MT-XXXX --squash --delete-branch
```

6. **Update Jira**:
```
Use tool: jira_transition_issue
issue_key: "MT-XXXX"
transition_id: "[ID for 'Done']"
comment: "Code reviewed and merged to main."
```

## Automation Triggers

### Manual Trigger
User says: "Start work on MT-XXXX"
→ Execute full workflow

### PR-based Trigger
When a new PR is opened:
1. Extract Jira key from PR title/description (MT-XXXX pattern)
2. Fetch ticket details
3. If ticket exists in MT project:
   - Check if branch follows naming convention
   - If not, create proper branch and switch PR to it
   - Run context gathering
   - Create kimi plan
   - Notify user: "Ready to execute plan for MT-XXXX"

## Command Reference

| Command | Action |
|---------|--------|
| `/jko:start MT-XXXX` | Start full workflow for ticket |
| `/jko:context MT-XXXX` | Fetch and display context only |
| `/jko:plan MT-XXXX` | Create GSD + kimi plans |
| `/jko:execute MT-XXXX` | Execute kimi plan |
| `/jko:review MT-XXXX` | Review as project manager |
| `/jko:status` | Show active tickets and status |

## File Locations

| Purpose | Location |
|---------|----------|
| Kimi plans | `~/.kimi/plans/MT-XXXX.md` |
| GSD context | `.planning/MT-XXXX-CONTEXT.md` |
| Figma assets | `.planning/assets/figma/` |
| Execution logs | `~/.kimi/logs/MT-XXXX.log` |

## Error Handling

If Jira fetch fails:
- Check ticket key format (MT-XXXX)
- Verify MCP Atlassian is configured
- Prompt user for manual input

If Confluence fetch fails:
- Log warning, continue without
- Note in context document

If Figma fetch fails:
- Log warning, continue without
- Note design context may be incomplete

If kimi execution fails:
- Capture logs from `~/.kimi/logs/`
- Create fix plan
- Re-execute or hand off to user

## Best Practices

1. **Always verify ticket scope** before planning
2. **Confirm branch name** with user if ambiguous
3. **Review GSD plans** before delegating to kimi
4. **Check for existing work** (branches, PRs)
5. **Update Jira promptly** to maintain traceability
6. **Preserve design assets** in `.planning/assets/`
7. **Use atomic commits** as per GSD standards

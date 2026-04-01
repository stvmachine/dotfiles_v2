# MCP Integration Reference

## Jira MCP Tools

### Get Issue
```
Tool: jira_get_issue
Parameters:
- issue_key: "MT-XXXX" (required)
- fields: "*all" or comma-separated list
- expand: "renderedFields,changelog"
- comment_limit: 10-20
```

### Search Issues
```
Tool: jira_search
Parameters:
- jql: "project = MT AND status = 'In Progress'"
- fields: "summary,status,assignee"
- limit: 10-50
```

### Add Comment
```
Tool: jira_add_comment
Parameters:
- issue_key: "MT-XXXX"
- body: "Markdown comment"
```

### Get Transitions
```
Tool: jira_get_transitions
Parameters:
- issue_key: "MT-XXXX"
```

### Transition Issue
```
Tool: jira_transition_issue
Parameters:
- issue_key: "MT-XXXX"
- transition_id: "[ID from get_transitions]"
- comment: "Transition comment"
```

### Get Development Info
```
Tool: jira_get_issue_development_info
Parameters:
- issue_key: "MT-XXXX"
```
Returns: linked PRs, commits, branches

## Confluence MCP Tools

### Get Page
```
Tool: confluence_get_page
Parameters:
- page_id: "123456789"
- convert_to_markdown: true
- include_metadata: true
```

### Search
```
Tool: confluence_search
Parameters:
- query: "search terms" or CQL
- limit: 10
```

### Get Children
```
Tool: confluence_get_page_children
Parameters:
- parent_id: "123456789"
- include_content: true
- convert_to_markdown: true
```

### Get Attachments
```
Tool: confluence_get_attachments
Parameters:
- content_id: "123456789"
```

## Figma MCP Tools

### Get File Data
```
Tool: get_figma_data
Parameters:
- fileKey: "ABC123xyz"
- nodeId: "123:456" (optional, specific node)
```

### Download Images
```
Tool: download_figma_images
Parameters:
- fileKey: "ABC123xyz"
- localPath: ".planning/assets/figma"
- nodes: [
    {
      nodeId: "123:456",
      fileName: "component.png",
      imageRef: "ref_from_file_data"
    }
  ]
```

## GitHub CLI Commands

### PR Management
```bash
# List PRs
gh pr list --search "MT-XXXX" --state open

# View PR
gh pr view [NUMBER] --json title,body,headRefName

# Create PR
gh pr create \
  --title "MT-XXXX: Summary" \
  --body "Description" \
  --base main

# Review PR
gh pr review [NUMBER] --approve --body "LGTM"
gh pr review [NUMBER] --request-changes --body "Issues..."

# Merge PR
gh pr merge [NUMBER] --squash --delete-branch
```

### Branch Management
```bash
# Create branch
git checkout -b feature/MT-XXXX-description

# Push branch
git push -u origin feature/MT-XXXX-description

# Check status
git status
git log --oneline -10
```

## GSD Commands

### Project Setup
```bash
# New project (if no .planning/)
/gsd:new-project [--auto]
```

### Phase Management
```bash
# Add phase
/gsd:add-phase

# Discuss phase
/gsd:discuss-phase [N]

# Plan phase
/gsd:plan-phase [N]

# Execute phase
/gsd:execute-phase [N]

# Verify work
/gsd:verify-work [N]

# Ship (create PR)
/gsd:ship [N]
```

### Status
```bash
# Progress
/gsd:progress

# Next step
/gsd:next
```

## Kimi CLI Commands

### Execute Plan
```bash
# Interactive
kimi --prompt "Execute plan in ~/.kimi/plans/MT-XXXX.md"

# Non-interactive (yolo mode)
kimi --yolo --print \
  --prompt "Execute plan..."

# With config
kimi --yolo --print \
  --config-file ~/.kimi/config.toml \
  --prompt "Execute plan..."
```

### Session Management
```bash
# Continue previous session
kimi --continue

# Specific session
kimi --session SESSION_ID
```

## Common Patterns

### Extract Jira Key from PR Title
```bash
PR_TITLE="MT-1234: Add new feature"
TICKET=$(echo "$PR_TITLE" | grep -oE 'MT-[0-9]+')
```

### Check if Branch Exists
```bash
if git show-ref --verify --quiet "refs/heads/$BRANCH"; then
    echo "Branch exists"
fi
```

### Find Confluence Links
```bash
echo "$TICKET_DESCRIPTION" | grep -oE 'https://medtasker\.atlassian\.net/wiki/spaces/[^/]+/pages/[0-9]+'
```

### Find Figma Links
```bash
echo "$TICKET_DESCRIPTION" | grep -oE 'https://www\.figma\.com/(file|design)/[a-zA-Z0-9]+'
```

## File Locations

| Purpose | Path |
|---------|------|
| Kimi plans | `~/.kimi/plans/MT-XXXX.md` |
| Kimi logs | `~/.kimi/logs/MT-XXXX-YYYYMMDD-HHMMSS.log` |
| Kimi config | `~/.kimi/config.toml` |
| GSD context | `.planning/MT-XXXX-CONTEXT.md` |
| GSD phases | `.planning/phase-N-*/` |
| Figma assets | `.planning/assets/figma/` |
| Skill location | `~/.claude/skills/jira-kimi-orchestrator/` |
| Commands | `~/.claude/commands/jira-kimi-orchestrator/` |

---
name: jira
description: Connect code work to Jira tickets — inbox for gathering full ticket context, read context, update status, link PRs, and auto-detect ticket IDs from branch names. Integrates with beads for persistent task tracking and stores ticket archives in ~/.medtasker-tickets/.
allowed-tools: mcp__mcp-atlassian__*, Bash(git *), Bash(curl *), Bash(file *), Bash(ls *), Bash(bd *), Read
---

# Jira Integration Skill

Connects code work to Jira tickets using the mcp-atlassian MCP server. Integrates with **beads** for persistent task tracking and multi-agent coordination.

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                         JIRA (Source of Truth)                   │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                    BEADS (Persistent Tracker)                    │
│  - Task status and lifecycle                                     │
│  - GitHub PR links                                               │
│  - Asset references (local paths)                                │
│  - Multi-agent coordination (claim, deps, etc.)                  │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────┐    ┌─────────────────────────────┐
│   ./todo/MT-XXXX/           │    │  ~/.medtasker-tickets/      │
│   (Working Cache)           │    │  (Archive Storage)          │
│  - TICKET_DESCRIPTION.md    │    │  - MT-XXXX/                 │
│  - assets/ (symlinked)      │◄──►│    - TICKET_DESCRIPTION.md  │
│  - context/                 │    │    - assets/                │
│  - .state.json              │    │    - context/               │
└─────────────────────────────┘    └─────────────────────────────┘
```

**Storage Locations:**
- **Jira**: Source of truth for ticket content, status, comments
- **beads**: Persistent task tracker with status, PR links, asset references
- **`./todo/MT-XXXX/`**: Local working cache (gitignored, human-friendly)
- **`~/.medtasker-tickets/`**: Centralized archive for resolved tickets

## Capabilities

### 0. Ticket Inbox (NEW)
Fetch a Jira ticket with full context and save to organized directory structure. This is the entry point for the automation pipeline.

Creates:
- `todo/MT-XXXX/TICKET_DESCRIPTION.md` — Main ticket content with metadata, description, and references
- `todo/MT-XXXX/assets/` — Downloaded images, documents, and attachments
- `todo/MT-XXXX/context/` — Fetched Confluence pages, Figma design data, GitHub PR summaries
- `todo/MT-XXXX/.state.json` — Agent handoff state file for downstream processing
- **beads task** — Persistent tracking with Jira ticket ID in title

See rules/fetch.md for detailed implementation.
See rules/update.md for re-fetching existing tickets.
See rules/beads-integration.md for beads task management.

### 1. Read ticket context
Fetch ticket details (summary, description, acceptance criteria, status, assignee) to understand what needs to be done. When a ticket exists in `todo/MT-XXXX/` (from inbox workflow), read from there. Otherwise, fetch directly:
- Save a `TICKET_DESCRIPTION.md` file in `./todo/MT-XXXX/` folder with the full ticket content
- Download ALL image/file attachments to `./todo/MT-XXXX/assets/` (changed from flat `./todo/MT-XXXX_filename`)
- Display images inline using the Read tool
- Reference local attachment paths in the markdown file

### 2. Update ticket with work
After completing work, update the Jira ticket:
- Add a comment summarizing what was done
- Link the PR URL
- Transition the ticket status (e.g. In Progress → In Review)

### 3. Auto-link from branch names
Extract Jira ticket IDs from git branch names automatically. Common patterns:
- `fix/MT-9548_description` → `MT-9548`
- `feat/MT-1234-description` → `MT-1234`
- `MT-1234_description` → `MT-1234`
- `feature/PROJ-123-thing` → `PROJ-123`

## Workflow

### When invoked with `inbox` (`/jira inbox MT-9548`)
1. Validate ticket key format (pattern: [A-Z]+-\d+)
2. Follow rules/fetch.md to fetch full ticket context
3. Follow rules/mcp-utils.md for MCP validation, retry, and credential patterns
4. Download all attachments to todo/MT-XXXX/assets/ (see rules/fetch.md)
5. Parse for Confluence links → follow rules/confluence.md if links found
6. Parse for Figma links → follow rules/figma-integration.md if links found
7. Parse for GitHub references → follow rules/github.md if references found
8. Create .state.json via rules/state-file.md pattern
9. **Create beads task** via rules/beads-integration.md (track in beads)
10. Display summary of what was fetched and what failed

### When invoked with `inbox update` (`/jira inbox update MT-9548`)
1. Validate ticket exists in todo/MT-XXXX/
2. Follow rules/update.md to re-fetch and overwrite all content
3. Update beads task if exists (sync status)

### When invoked without arguments (`/jira`)
1. Detect the current git branch
2. Extract ticket ID from branch name (pattern: `[A-Z][A-Z0-9]+-\d+`)
3. If found, fetch and display the ticket details
4. If not found, ask the user for a ticket ID

### When invoked with a ticket ID (`/jira MT-9548`)
1. Fetch and display the ticket details

### When invoked with `update` (`/jira update`)
1. Detect ticket ID from current branch
2. Gather context: recent commits, current PR (if any via `gh pr view`)
3. Post a comment to the ticket summarizing the work done
4. Update beads task with PR link if available
5. Ask user if they want to transition the ticket status

### When invoked with `link` (`/jira link`)
1. Detect ticket ID from current branch
2. Find the current PR via `gh pr view --json url`
3. Add the PR URL as a comment on the Jira ticket
4. Update beads task with PR link
5. Format: `PR: <url> — <pr title>`

### When invoked with `start` (`/jira start MT-9548`)
1. Transition the ticket to "In Progress"
2. Claim the beads task (if exists)
3. Display the ticket details for context

### When invoked with `archive` (`/jira archive MT-9548`)
1. Move ticket from `./todo/MT-9548/` to `~/.medtasker-tickets/MT-9548/`
2. Update beads task status to "archived"
3. Keep assets and context intact in archive location
4. Remove from local working cache

## Extracting Ticket ID

Use this regex on the current git branch name:
```
([A-Z][A-Z0-9]+-\d+)
```

Run: `git branch --show-current` then extract the match.

## IMPORTANT: Always Fetch Full Ticket Context

When displaying any ticket, ALWAYS fetch and show the complete context automatically. Never require the user to ask for additional details. This includes:

### Attachments & Images
1. Fetch the ticket with `expand=renderedFields` to get attachment references
2. Download ALL attachments to the project's `./todo/MT-XXXX/assets/` folder (changed from flat `./todo/MT-XXXX_filename`) using curl with `-L` flag (Jira redirects)
3. **Deduplication:** Check the centralized attachment index (`~/.medtasker-tickets/.index/confluence-index.json`) before downloading Confluence content. Images and other assets are stored per-ticket.
4. Display image attachments inline using the Read tool (supports PNG, JPG, etc.)
5. List non-image attachments with their filenames and sizes
6. Reference the local paths in the TICKET_DESCRIPTION.md file

Authentication for downloads:
```bash
curl -s -L -u "$JIRA_USERNAME:$JIRA_API_TOKEN" -o ./todo/MT-1234/assets/screenshot.png "https://medtasker.atlassian.net/rest/api/3/attachment/content/<id>"
```

Read credentials from `~/.claude/mcp.json`:
```bash
python3 -c "import json; c=json.load(open('$HOME/.claude/mcp.json'))['mcpServers']['mcp-atlassian']['env']; print(c['JIRA_USERNAME']); print(c['JIRA_API_TOKEN'])"
```

**Attachment Deduplication:**
- **Confluence only**: `~/.medtasker-tickets/.index/confluence-index.json` (cross-project)
- Images and other assets: stored per-ticket in `~/.medtasker-tickets/MT-XXXX/assets/`
- Key: Confluence page URL
- Scope: Confluence pages are deduplicated across all tickets

### Issue Links
Show all linked issues (blocks, is blocked by, relates to, etc.) with their key, summary, and status.

### Comments
Show the last 3 comments with author, date, and content.

### Subtasks
List all subtasks with key, summary, and status.

### Full Display Format

```
**<KEY>: <Summary>**

| Field | Value |
|-------|-------|
| **Status** | ... |
| **Type** | ... |
| **Assignee** | ... |
| **Priority** | ... |
| **Sprint** | ... |
| **Labels** | ... |
| **Beads** | bd-xxxxx (if tracked) |

**Description:**
<rendered description text>

**Attachments:**
<display each image inline, list other files>

**Links:**
- blocks: MT-1234 - Summary [Status]
- relates to: MT-5678 - Summary [Status]

**Subtasks:**
- MT-9999 - Summary [Status]

**Recent Comments:**
[date] Author: comment text
```

## Comment Formatting

When posting comments to Jira, use **Markdown syntax** (not Jira wiki markup). The MCP server converts Markdown to Jira's ADF format automatically.

**Always use the jira-markup skill** for reference on correct formatting.

### Quick Reference

| Element | Syntax | Example |
|---------|--------|---------|
| Heading | `## Title` | `## Code Update` |
| Bold | `**text**` | `**Branch:**` |
| Italic | `*text*` | `*branch_name*` |
| Code inline | `` `code` `` | `` `feature/MT-1234` `` |
| Link | `[text](url)` | `[PR Title](https://github.com/...)` |
| Bullet list | `- item` | `- First item` |
| Numbered list | `1. item` | `1. First step` |

### Example Comment

```markdown
## Code Update

**Branch:** `feature/MT-1234-fix`
**PR:** [PR Title](https://github.com/nimblic/medtasker-app/pull/97)

**Commits:**
1. Initial implementation
2. Added tests
3. Fixed review feedback

**Summary:** Brief description of what was done.
```

### Full Formatting Guide

For complete formatting reference, see the **jira-markup skill**.

## Status Transitions

Common transitions to offer:
- **To Do → In Progress**: When starting work (`/jira start`)
- **In Progress → In Review**: When PR is created (`/jira link` or `/jira update`)
- **In Review → Done**: When PR is merged

Always confirm with the user before transitioning status.

## Error Handling

- If MCP server is not connected, tell the user to fill in credentials in `~/.claude/mcp.json`
- If ticket not found, suggest checking the ticket ID
- If branch has no ticket ID pattern, ask the user to provide one
- If beads is not initialized, run `bd init --stealth` in the project

## Rules

Detailed implementation patterns are in the `rules/` subdirectory:

- `rules/mcp-utils.md` — MCP validation, retry logic, credential extraction, sequential processing
- `rules/state-file.md` — Agent handoff state file format and creation
- `rules/fetch.md` — Core ticket fetch, directory creation, attachment download, link preservation
- `rules/update.md` — Re-fetch and overwrite existing tickets
- `rules/confluence.md` — Confluence page extraction and saving
- `rules/github.md` — GitHub PR/repo reference analysis
- `rules/beads-integration.md` — Beads task creation, updates, and multi-agent coordination

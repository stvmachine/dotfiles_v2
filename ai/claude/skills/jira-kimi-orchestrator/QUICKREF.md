# Jira-Kimi Orchestrator - Quick Reference

## Commands

| Command | Purpose |
|---------|---------|
| `/jko:start MT-XXXX` | Start full workflow for ticket |
| `/jko:context MT-XXXX` | View ticket context only |
| `/jko:plan MT-XXXX` | Create GSD + kimi plans |
| `/jko:execute MT-XXXX` | Run kimi to implement |
| `/jko:review MT-XXXX` | PM review and merge |
| `/jko:status` | Show active workflows |

## Workflow Steps

```
┌─────────────────────────────────────────────────────────────┐
│  1. /jko:start MT-XXXX                                      │
│     └─ Fetch Jira + Confluence + Figma                     │
│                                                            │
│  2. (auto) Create branch                                    │
│     └─ feature/MT-XXXX-description                         │
│                                                            │
│  3. (auto) GSD Planning                                     │
│     └─ discuss → plan phases                               │
│                                                            │
│  4. /jko:execute MT-XXXX                                    │
│     └─ kimi implements code                                │
│                                                            │
│  5. /jko:review MT-XXXX                                     │
│     └─ Review → Approve → Merge                            │
└─────────────────────────────────────────────────────────────┘
```

## File Locations

| Type | Path |
|------|------|
| Kimi Plans | `~/.kimi/plans/MT-XXXX.md` |
| Kimi Logs | `~/.kimi/logs/MT-XXXX-*.log` |
| Context | `.planning/MT-XXXX-CONTEXT.md` |
| Figma Assets | `.planning/assets/figma/` |

## Prerequisites

- [ ] `npx get-shit-done-cc@latest --claude --global`
- [ ] `gh auth login`
- [ ] `pip install kimi-cli`
- [ ] MCP Atlassian configured
- [ ] MCP Figma configured (optional)

## Common Patterns

### Work on New Ticket
```
/jko:start MT-1234
/jko:execute MT-1234
/jko:review MT-1234
```

### Check Status
```
/jko:status
```

### Handle Existing PR
```
/jko:context MT-1234
/jko:review MT-1234
```

## Troubleshooting

| Issue | Solution |
|-------|----------|
| MCP not working | Check env vars, test with simple query |
| kimi fails | Check `~/.kimi/logs/MT-XXXX-*.log` |
| GSD not init | Run `/gsd:new-project` first |
| Branch exists | Claude will offer to reuse or create new |

## Links

- Full Skill: `~/.claude/skills/jira-kimi-orchestrator/`
- Examples: `references/WORKFLOW_EXAMPLES.md`
- MCP Ref: `references/MCP_INTEGRATION.md`

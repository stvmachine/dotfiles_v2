# GSD-Kimi Integration with Jira-Kimi Orchestrator

This document explains how GSD-Kimi integrates with the Jira-Kimi orchestrator workflow.

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                      User Interface                              │
├─────────────────────────────────────────────────────────────────┤
│  Option 1: Claude + /jko:start MT-XXXX                          │
│  Option 2: CLI + jira-gsd-orchestrator.sh MT-XXXX               │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                     Jira Context Layer                           │
│  ┌─────────────┐  ┌──────────────┐  ┌──────────────┐           │
│  │ Jira Ticket │  │  Confluence  │  │    Figma     │           │
│  │  (MT-XXXX)  │  │   Pages      │  │   Designs    │           │
│  └─────────────┘  └──────────────┘  └──────────────┘           │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                      GSD Planning Layer                          │
│  ┌─────────────┐  ┌──────────────┐  ┌──────────────┐           │
│  │  discuss    │  │    plan      │  │   context    │           │
│  │   phase     │───►   phase     │───►   docs      │           │
│  └─────────────┘  └──────────────┘  └──────────────┘           │
│         │                                     │                 │
│         └─────────────────────────────────────┘                 │
│                              │                                  │
│                              ▼                                  │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │                  .planning/ directory                    │   │
│  │  ├── PROJECT.md                                         │   │
│  │  ├── REQUIREMENTS.md                                    │   │
│  │  ├── ROADMAP.md                                         │   │
│  │  └── phase-1-MT-XXXX/                                   │   │
│  │      ├── 1-CONTEXT.md                                   │   │
│  │      ├── 1-RESEARCH.md                                  │   │
│  │      └── 1-1-PLAN.md                                    │   │
│  └─────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                     Execution Layer                              │
│                                                                  │
│  Option A: Claude Sub-agents                                    │
│  /gsd:execute-phase → Spawn agents → Implement → Commit         │
│                                                                  │
│  Option B: Kimi Agent                                           │
│  kimi --agent-file gsd-agent.yaml → Read plan → Execute         │
│                                                                  │
│  Option C: Direct kimi                                          │
│  kimi --prompt "Execute plan in..." → Implement                 │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                     Completion Layer                             │
│  ┌─────────────┐  ┌──────────────┐  ┌──────────────┐           │
│  │   SUMMARY   │  │     PR       │  │ Jira Update  │           │
│  │     .md     │───►   Created   │───►   Status     │           │
│  └─────────────┘  └──────────────┘  └──────────────┘           │
└─────────────────────────────────────────────────────────────────┘
```

## Integration Points

### 1. Jira Context → GSD Context

Jira ticket details populate `.planning/phase-N/CONTEXT.md`:

```yaml
Source: Jira MT-XXXX
↓
Extract:
  - Summary → Phase goal
  - Description → Technical context
  - Acceptance Criteria → Verification checklist
  - Confluence links → Additional context
  - Figma links → Design specifications
↓
Target: .planning/phase-1-MT-XXXX/1-CONTEXT.md
```

### 2. GSD Plans → Kimi Execution

GSD XML plans are executed by kimi:

```xml
<!-- .planning/phase-1/1-1-PLAN.md -->
<task type="auto" priority="1">
  <id>1-1-001</id>
  <name>Create component</name>
  <files>src/Component.tsx</files>
  <action>
    Create React component with props interface...
  </action>
  <verify>
    Component renders without errors
  </verify>
</task>
↓
kimi agent reads task
↓
Implements changes
↓
Commits: feat(Component): create component
```

### 3. Execution → Jira Update

After kimi execution:

```bash
1. Write SUMMARY.md
2. Create PR: gh pr create
3. Update Jira: jira_add_comment
4. Transition: jira_transition_issue
```

## Usage Patterns

### Pattern 1: Claude-First (Full Automation)

```bash
# In Claude with Jira-Kimi Orchestrator skill
/jko:start MT-1234
# → Fetches Jira
# → Creates branch
# → Runs GSD planning
# → Creates kimi plan

/jko:execute MT-1234
# → Runs kimi with plan

/jko:review MT-1234
# → Reviews and merges
```

### Pattern 2: CLI-First (Manual Control)

```bash
# Fetch Jira context manually
jira-gsd-orchestrator.sh MT-1234 fetch

# Initialize GSD
jira-gsd-orchestrator.sh MT-1234 init

# Edit context and plans manually
vim .planning/phase-1-MT-1234/1-CONTEXT.md
vim .planning/phase-1-MT-1234/1-1-PLAN.md

# Execute with kimi
jira-gsd-orchestrator.sh MT-1234 execute
```

### Pattern 3: Hybrid (Claude Plan, Kimi Execute)

```bash
# In Claude
/jko:start MT-1234
# Stop after planning phase

# In terminal
kimi --agent-file ~/.kimi/skills/gsd-kimi/gsd-agent.yaml \
     --yolo \
     --prompt "Execute plans in .planning/phase-1-MT-1234/"

# Back in Claude
/jko:review MT-1234
```

### Pattern 4: Direct Kimi (Minimal Tooling)

```bash
# Create plan manually
cat > ~/.kimi/plans/MT-1234.md << 'EOF'
# Plan for MT-1234

## Context
[From Jira]

## Steps
1. Create file X
2. Implement feature Y
3. Add tests

## Git
```bash
git add .
git commit -m "feat(MT-1234): implementation"
git push
```
EOF

# Execute
kimi --yolo --prompt "Execute plan in ~/.kimi/plans/MT-1234.md"
```

## Configuration

### Claude Side

In `~/.claude/skills/jira-kimi-orchestrator/`:
- Set `execution_method = "kimi"` in config
- Path to kimi agent: `~/.kimi/skills/gsd-kimi/gsd-agent.yaml`

### Kimi Side

In `~/.kimi/config.toml`:
```toml
[gsd]
enabled = true
planning_dir = ".planning"
default_agent = "~/.kimi/skills/gsd-kimi/gsd-agent.yaml"
```

### Project Side

In `.planning/config.json`:
```json
{
  "execution": {
    "engine": "kimi",
    "agent_file": "~/.kimi/skills/gsd-kimi/gsd-agent.yaml",
    "auto_commit": true,
    "verify_each_task": true
  }
}
```

## Data Flow

```
Jira MT-XXXX
    │
    ├──► Summary ────────► Phase name
    ├──► Description ────► Context details
    ├──► AC ─────────────► Verification checklist
    ├──► Confluence ─────► Additional context
    └──► Figma ──────────► Design specs
              │
              ▼
    .planning/phase-1-MT-XXXX/
        ├── 1-CONTEXT.md (all context)
        ├── 1-RESEARCH.md (if needed)
        └── 1-1-PLAN.md (execution plan)
              │
              ▼
        kimi execution
              │
              ▼
        Code changes + Commits
              │
              ▼
        PR + Jira update
```

## Best Practices

1. **Context Synchronization**
   - Always pull latest Jira before planning
   - Update Jira when execution starts
   - Link PR to Jira ticket

2. **Plan Granularity**
   - Keep plans under 500 lines
   - Max 10 tasks per plan
   - Use multiple plans for complex phases

3. **Execution Verification**
   - Define verification steps in plan
   - Run tests after each task
   - Update acceptance criteria

4. **Error Handling**
   - If kimi fails, review logs
   - Fix plan and retry
   - Update context with learnings

## Troubleshooting Integration

| Issue | Cause | Solution |
|-------|-------|----------|
| kimi doesn't find agent | Path issue | Use full path to agent file |
| Plans not executing | XML format error | Validate XML structure |
| Jira not updating | Missing MCP | Check mcp-atlassian config |
| Context out of sync | Manual edits | Re-run fetch step |

## Future Enhancements

1. **Automatic Triggering**
   - Jira webhook → Auto-start workflow
   - PR open → Auto-fetch context

2. **Enhanced Context**
   - Git history analysis
   - Codebase mapping
   - Dependency tracking

3. **Smart Planning**
   - AI-assisted phase breakdown
   - Effort estimation
   - Risk identification

4. **Improved Execution**
   - Parallel task execution
   - Automatic rollback
   - Progress reporting

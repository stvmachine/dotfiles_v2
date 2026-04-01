# GSD for Kimi - Quick Start Guide

## Installation (One-time)

```bash
# 1. Ensure gsd-kimi is in ~/.kimi/skills/
cd ~/.kimi/skills/gsd-kimi

# 2. Run installer
./install.sh

# 3. Verify installation
gsd status
```

## Basic Workflow

### 1. Initialize Project

```bash
cd your-project
gsd init
```

This creates `.planning/` directory with:
- `PROJECT.md` - Project overview
- `STATE.md` - Current state tracking
- `config.json` - GSD configuration

### 2. Create Milestone

```bash
gsd new-milestone
# Enter milestone name when prompted
```

Creates:
- `REQUIREMENTS.md` - Milestone requirements
- `ROADMAP.md` - Phase roadmap

### 3. Work Through Phases

For each phase in your roadmap:

```bash
# Create context
gsd discuss-phase 1

# Create plans
gsd plan-phase 1

# Execute with kimi
kimi --agent-file ~/.kimi/skills/gsd-kimi/gsd-agent.yaml \
     --yolo \
     --prompt "Execute all plans in .planning/phase-1/"
```

## Jira Integration

For Jira ticket workflow:

```bash
# Use the orchestrator
~/.kimi/skills/gsd-kimi/scripts/jira-gsd-orchestrator.sh MT-1234

# Or step by step:
~/.kimi/skills/gsd-kimi/scripts/jira-gsd-orchestrator.sh MT-1234 fetch
~/.kimi/skills/gsd-kimi/scripts/jira-gsd-orchestrator.sh MT-1234 init
~/.kimi/skills/gsd-kimi/scripts/jira-gsd-orchestrator.sh MT-1234 plan
~/.kimi/skills/gsd-kimi/scripts/jira-gsd-orchestrator.sh MT-1234 execute
```

## File Editing

### Edit Context
```bash
# Edit .planning/phase-1-*/1-CONTEXT.md
# Add:
# - Implementation decisions
# - Technical approach
# - Constraints
```

### Edit Plan
```bash
# Edit .planning/phase-1-*/1-1-PLAN.md
# Add specific tasks:
# <task type="auto" priority="1">
#   <id>1-1-001</id>
#   <name>Create component</name>
#   <files>src/Component.tsx</files>
#   <action>Implement...</action>
#   <verify>Component renders</verify>
# </task>
```

## Kimi Execution

### Basic Execution
```bash
kimi --yolo --prompt "Execute plan in .planning/phase-1/1-1-PLAN.md"
```

### With GSD Agent
```bash
kimi --agent-file ~/.kimi/skills/gsd-kimi/gsd-agent.yaml \
     --yolo \
     --prompt "Execute all plans in .planning/phase-1/"
```

### Manual Step-by-Step
```bash
# In kimi:
# 1. Read plan
ReadFile: path=".planning/phase-1/1-1-PLAN.md"

# 2. Execute first task
ReadFile: path="src/file.ts"
# ... make changes ...
Shell: command="git add . && git commit -m 'feat: task 1'"

# 3. Continue to next task
# ...
```

## Tips

1. **Keep plans small** (< 10 tasks, < 500 lines)
2. **Use priority** (1 = highest, 5 = lowest)
3. **Define verification** for each task
4. **Commit atomically** after each task
5. **Write summaries** when phases complete

## Troubleshooting

| Issue | Solution |
|-------|----------|
| "gsd: command not found" | Run `./install.sh` or use `python3 ~/.kimi/skills/gsd-kimi/gsd.py` |
| "Phase not found" | Run `gsd discuss-phase N` first |
| Plans not executing | Check XML format, ensure `<task>` elements present |
| kimi not recognizing agent | Use full path: `--agent-file ~/.kimi/skills/gsd-kimi/gsd-agent.yaml` |

## Next Steps

- Read full documentation: `~/.kimi/skills/gsd-kimi/README.md`
- See examples: `~/.kimi/skills/gsd-kimi/templates/`
- Understand agents: `~/.kimi/skills/gsd-kimi/agents/`

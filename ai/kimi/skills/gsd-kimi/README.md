# GSD (Get Shit Done) for Kimi CLI

A standalone spec-driven development system that works directly with kimi-cli. This is a port/adaptation of the GSD methodology for use with Kimi CLI instead of Claude.

## What is GSD?

GSD is a spec-driven development methodology that provides:
- Structured planning and research
- Atomic execution plans
- Systematic verification
- Clean git history

## Installation

```bash
# Clone or copy this directory to ~/.kimi/skills/gsd-kimi
cd ~/.kimi/skills/gsd-kimi

# Run install script
chmod +x install.sh
./install.sh

# Or install manually
pip install -e .
```

## Quick Start

```bash
# 1. Initialize GSD project
gsd init

# 2. Create milestone
gsd new-milestone

# 3. Work through phases
gsd discuss-phase 1  # Create context
gsd plan-phase 1     # Create plans

# 4. Execute with kimi
kimi --agent-file ~/.kimi/skills/gsd-kimi/gsd-agent.yaml \
    --prompt "Execute all plans in .planning/phase-1/"
```

## Commands

### CLI Commands (gsd)

| Command | Description |
|---------|-------------|
| `gsd init` | Initialize GSD project |
| `gsd status` | Show current status |
| `gsd new-milestone` | Create new milestone |
| `gsd discuss-phase N` | Create context for phase N |
| `gsd plan-phase N` | Create plans for phase N |

### Kimi Slash Commands

When using the GSD agent file:

| Command | Description |
|---------|-------------|
| `/gsd:init` | Initialize project |
| `/gsd:status` | Show status |
| `/gsd:new-milestone` | Create milestone |
| `/gsd:discuss-phase N` | Discuss phase |
| `/gsd:plan-phase N` | Plan phase |
| `/gsd:execute-phase N` | Execute phase |

## Directory Structure

```
.planning/
├── config.json           # GSD configuration
├── PROJECT.md            # Project overview
├── REQUIREMENTS.md       # Milestone requirements
├── ROADMAP.md            # Phase roadmap
├── STATE.md              # Current state
└── phase-1-name/         # Phase directory
    ├── 1-CONTEXT.md      # Phase context
    ├── 1-RESEARCH.md     # Research findings
    ├── 1-1-PLAN.md       # Execution plan
    └── 1-SUMMARY.md      # Completion summary
```

## Plan Format

Plans use XML structure:

```xml
<plan>
  <metadata>
    <phase>1</phase>
    <plan>1</plan>
    <name>Implementation</name>
  </metadata>
  
  <tasks>
    <task type="auto" priority="1">
      <id>1-1-001</id>
      <name>Setup</name>
      <files>src/config.ts</files>
      <action>Implement configuration</action>
      <verify>Config loads correctly</verify>
    </task>
  </tasks>
</plan>
```

## Workflow

```
┌─────────────┐
│   gsd init  │
└──────┬──────┘
       ▼
┌─────────────┐
│ new-milestone│
└──────┬──────┘
       ▼
┌─────────────────────────────────────────┐
│ discuss-phase → plan-phase → execute   │
│ (repeat for each phase)                │
└─────────────────────────────────────────┘
```

## Configuration

Edit `.planning/config.json`:

```json
{
  "mode": "interactive",
  "granularity": "standard",
  "agents": {
    "research": true,
    "plan_check": true,
    "verifier": true
  },
  "git": {
    "branching_strategy": "phase",
    "commit_docs": true
  }
}
```

## Comparison with Claude GSD

| Feature | Claude GSD | GSD for Kimi |
|---------|-----------|--------------|
| Planning | `/gsd:plan-phase` | `gsd plan-phase` + kimi |
| Execution | Sub-agents | Kimi execution |
| Verification | Auto + Manual | Manual via kimi |
| Webhooks | Supported | Not supported |
| Sub-agents | Yes | Use kimi directly |

## Differences from Original GSD

This is a **standalone** implementation that:
- Works without Claude
- Uses kimi-cli's native capabilities
- Simpler agent orchestration
- Direct kimi execution

Original GSD features not (yet) implemented:
- Automatic sub-agent spawning
- Parallel plan execution
- Webhook triggers
- Complex wave management

## Tips

1. **Keep plans small** - Under 500 lines, max 10 tasks per plan
2. **Use atomic commits** - One commit per task
3. **Verify as you go** - Don't skip verification steps
4. **Update STATE.md** - Keep state current
5. **Write summaries** - Document what was done

## Troubleshooting

### "GSD not initialized"
Run `gsd init` in project root.

### "Phase not found"
Run `gsd discuss-phase N` before `gsd plan-phase N`.

### Plans not executing
Ensure plan files follow XML format with proper `<task>` elements.

## License

MIT

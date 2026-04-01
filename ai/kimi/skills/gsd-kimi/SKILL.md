---
name: gsd-kimi
description: Get Shit Done (GSD) - A spec-driven development system for kimi-cli. Provides structured planning, research, execution, and verification workflows. Use for complex development tasks requiring multi-phase planning, research, and systematic execution. Triggers: plan project, create roadmap, gsd init, discuss phase, execute phase, verify work.
---

# GSD for Kimi

A standalone spec-driven development system that works directly with kimi-cli.

## Overview

GSD provides a structured workflow for software development:
1. **Initialize** - Set up project structure
2. **Discuss** - Gather context and decisions
3. **Plan** - Research and create execution plans
4. **Execute** - Implement in waves
5. **Verify** - Confirm work meets requirements
6. **Ship** - Create PR and deliver

## Directory Structure

```
.planning/
├── PROJECT.md           # Project definition
├── REQUIREMENTS.md      # Scoped requirements
├── ROADMAP.md           # Phase roadmap
├── STATE.md             # Current state/decisions
├── phase-{N}-{slug}/    # Phase directories
│   ├── CONTEXT.md       # Phase context
│   ├── RESEARCH.md      # Research findings
│   ├── {N}-{M}-PLAN.md  # Execution plans
│   └── SUMMARY.md       # Completion summary
└── config.json          # GSD configuration
```

## Commands

### `/gsd:init [project-name]`
Initialize new GSD project.

Steps:
1. Create `.planning/` directory
2. Generate `PROJECT.md` with project definition
3. Create `STATE.md` for tracking
4. Generate `config.json`

### `/gsd:new-milestone`
Create new milestone with roadmap.

Steps:
1. Interview user for requirements
2. Create `REQUIREMENTS.md`
3. Generate `ROADMAP.md` with phases
4. Update `STATE.md`

### `/gsd:discuss-phase [N]`
Discuss phase implementation details.

Steps:
1. Load phase from ROADMAP.md
2. Analyze gray areas
3. Ask targeted questions
4. Create `{N}-CONTEXT.md`

### `/gsd:plan-phase [N]`
Research and plan phase execution.

Steps:
1. Read `{N}-CONTEXT.md`
2. Spawn research agent
3. Create execution plans
4. Verify plans against requirements
5. Write `{N}-{M}-PLAN.md` files

### `/gsd:execute-phase [N]`
Execute phase plans.

Steps:
1. Load all `{N}-{M}-PLAN.md` files
2. Group into waves by dependencies
3. Execute plans in parallel waves
4. Commit per task
5. Write `{N}-SUMMARY.md`

### `/gsd:verify-phase [N]`
Verify phase completion.

Steps:
1. Compare against phase goals
2. Check acceptance criteria
3. Identify gaps
4. Create fix plans if needed

### `/gsd:ship [N]`
Ship phase as PR.

Steps:
1. Create PR branch
2. Generate PR description
3. Push and create PR
4. Update STATE.md

### `/gsd:status`
Show current status.

Displays:
- Current milestone
- Active phase
- Completed phases
- Next steps

## Plan Format

Plans use structured XML format optimized for AI execution:

```xml
<plan>
  <metadata>
    <phase>1</phase>
    <name>User Authentication</name>
    <goal>Implement login/logout</goal>
  </metadata>
  
  <tasks>
    <task type="auto" priority="1">
      <name>Create User Model</name>
      <files>src/models/user.ts</files>
      <action>
        Define User interface with id, email, passwordHash, createdAt.
        Use TypeScript strict types.
      </action>
      <verify>File exists and exports User type</verify>
      <done>User model defined</done>
    </task>
    
    <task type="auto" priority="2">
      <name>Implement Login Endpoint</name>
      <files>src/api/auth/login.ts</files>
      <dependencies>User Model</dependencies>
      <action>
        Create POST /api/auth/login endpoint.
        Validate credentials, return JWT.
      </action>
      <verify>curl -X POST returns 200 with token</verify>
      <done>Login endpoint working</done>
    </task>
  </tasks>
</plan>
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

## Workflow Example

```
# Initialize project
/gsd:init my-app

# Create milestone
/gsd:new-milestone
> What do you want to build? "A task management app"

# Work through phases
/gsd:discuss-phase 1
/gsd:plan-phase 1
/gsd:execute-phase 1
/gsd:verify-phase 1
/gsd:ship 1

# Continue to next phase
/gsd:discuss-phase 2
...
```

## Agent Specifications

Research Agent (`agents/research.md`):
- Investigates domain
- Identifies best practices
- Finds potential pitfalls

Planning Agent (`agents/planning.md`):
- Creates execution plans
- Breaks down tasks
- Defines verification

Execution Agent (`agents/execution.md`):
- Implements tasks
- Handles errors
- Commits atomically

## Templates

See `templates/` directory for:
- PROJECT.md template
- REQUIREMENTS.md template
- PLAN.md template
- SUMMARY.md template

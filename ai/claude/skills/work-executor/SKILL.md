---
name: work-executor
description: End-to-end ticket processing from todo/ queue through GSD planning and Kimi implementation. Single entry point for the automation pipeline.
allowed-tools: Read, Write, Bash(git *), Bash(kimi *), Bash(pnpm *), Bash(node *), Bash(gh *), Bash(python3 *), Bash(mkdir *), Bash(cp *), Bash(mv *), Bash(cat *), Bash(ls *), Bash(grep *), Bash(date *), mcp__chrome-devtools__*
---

# Work Executor Skill

Process Jira tickets through automatic GSD planning and autonomous Kimi execution.

## Workflow

1. **Ticket Selection** -> Follow rules/ticket-selection.md
2. **Branch Creation** -> Follow rules/branch-management.md
3. **Context Consolidation + GSD Orchestration** -> Follow rules/context-consolidation.md, then rules/gsd-orchestration.md
4. **Kimi Execution** -> Follow rules/kimi-execution.md
5. **Quality Gates** -> Follow rules/test-retry-loop.md + rules/lint-validation.md
6. **Human Checkpoint** -> Follow rules/human-checkpoint.md

Each rule is self-contained with clear inputs/outputs and error handling.

## Entry Point

When invoked (e.g., `/work` or `/work MT-XXXX`):
- If a ticket ID is provided as argument, skip selection and use that ticket directly
- If no argument, follow rules/ticket-selection.md to pick from INDEX.md
- Then proceed through steps 2-6 sequentially

## Prerequisites

- Tickets must be fetched via `/jira inbox MT-XXXX` first
- Kimi CLI must be installed and available in PATH
- Current directory must be the project root (where todo/ lives)

## Rules

- `rules/index-management.md` -- INDEX.md read/write/update patterns
- `rules/ticket-selection.md` -- Pick ticket from queue (D-01, D-02, D-03)
- `rules/branch-management.md` -- Feature branch creation (EXEC-01)
- `rules/context-consolidation.md` -- Consolidate ticket data for GSD (PLAN-02)
- `rules/gsd-orchestration.md` -- Auto-run discuss->plan->execute (D-04, D-09)
- `rules/kimi-execution.md` -- Invoke Kimi with GSD agent mode (D-07, D-08)
- `rules/test-retry-loop.md` -- 3-attempt retry with escalation (D-10-D-13)
- `rules/lint-validation.md` -- Linting and formatting checks (EXEC-04)
- `rules/human-checkpoint.md` -- Approval gate before external actions (D-05, D-14)

# Jira-Kimi Orchestrator - Workflow Examples

## Example 1: New Feature Development

### Scenario
New feature request in Jira: MT-1234 "Add patient search to dashboard"

### Workflow

```bash
# User in Claude:
/jko:start MT-1234
```

**Claude Actions:**
1. Fetches MT-1234 from Jira
   - Summary: "Add patient search to dashboard"
   - Description: Search by name, MRN, DOB
   - Acceptance criteria listed
   - Links to Confluence: "Dashboard Search Design"

2. Fetches Confluence page
   - Design specifications
   - API requirements

3. Creates branch: `feature/MT-1234-add-patient-search`

4. Creates context document: `.planning/MT-1234-CONTEXT.md`

5. Runs GSD discuss-phase
   - Presents context to user
   - Confirms search approach

6. Runs GSD plan-phase
   - Creates research and plans

7. Creates kimi plan: `~/.kimi/plans/MT-1234.md`

**User:**
```bash
/jko:execute MT-1234
```

**Claude Actions:**
1. Runs kimi with plan
2. Monitors execution
3. kimi:
   - Implements search component
   - Adds API integration
   - Creates tests
   - Commits changes
   - Pushes branch

4. Creates PR

5. Updates Jira ticket to "In Review"

**User:**
```bash
/jko:review MT-1234
```

**Claude Actions (Project Manager):**
1. Reviews PR diff
2. Checks against acceptance criteria
3. Approves and merges
4. Updates Jira to "Done"

---

## Example 2: Bug Fix

### Scenario
Bug report: MT-5678 "Login button not working on mobile"

### Workflow

```bash
/jko:start MT-5678
```

**Claude Actions:**
1. Fetches ticket
   - Bug description
   - Steps to reproduce
   - Expected vs actual behavior
   - Figma link to mobile designs

2. Fetches Figma file
   - Downloads mobile button specs

3. Creates branch: `feature/MT-5678-login-button-mobile-fix`

4. Context includes:
   - Reproduction steps
   - Device/OS info
   - Design specs from Figma

5. GSD planning creates focused plan

6. Kimi plan: Simple fix with verification

```bash
/jko:execute MT-5678
```

**kimi executes:**
- Fixes CSS media query
- Updates button component
- Tests on responsive breakpoints
- Commits: `fix(MT-5678): resolve login button on mobile`

```bash
/jko:review MT-5678
```

**Claude:**
- Reviews one-line CSS fix
- Approves and merges
- Updates Jira

---

## Example 3: Complex Integration

### Scenario
MT-9012 "Integrate with new billing API"

### Workflow

```bash
/jko:start MT-9012
```

**Context gathering:**
1. Jira ticket with:
   - API documentation link (Confluence)
   - Sequence diagram (Figma)
   - Multiple acceptance criteria
   - Related tickets: MT-9013, MT-9014

2. Fetches:
   - Confluence: API integration guide
   - Confluence: Authentication setup
   - Figma: User flow diagrams

3. Creates comprehensive context document

4. GSD planning:
   - Phase 1: API client setup
   - Phase 2: Authentication
   - Phase 3: Endpoint integration
   - Phase 4: Error handling
   - Phase 5: Testing

5. Creates master kimi plan with phases

```bash
/jko:execute MT-9012
```

**kimi executes in phases:**
- Each phase gets atomic commits
- Tests added per phase
- Documentation updated

**Review process:**
- Claude reviews each phase
- May request adjustments
- Final approval and merge

---

## Example 4: Handling Existing PR

### Scenario
User opens PR manually, wants to continue with workflow

### Workflow

```bash
# PR exists with title "MT-1111: Add notifications"
/jko:start MT-1111
```

**Claude detects:**
- Existing PR for MT-1111
- Offers options:
  1. Review existing PR
  2. Continue with new implementation
  3. Update PR with new changes

**User selects:** Continue with new implementation

**Claude:**
- Creates new branch with different suffix
- Fetches context
- Runs planning
- kimi executes
- Creates separate PR

---

## Example 5: Multiple Related Tickets

### Scenario
Epic MT-2000 with subtasks MT-2001, MT-2002, MT-2003

### Workflow

```bash
# Start with Epic context
/jko:context MT-2000
```

**Claude shows:**
- Epic description
- All linked subtasks
- Overall architecture

```bash
# Work on first subtask
/jko:start MT-2001
```

**Claude:**
- Fetches subtask
- Cross-references Epic context
- Plans with Epic architecture in mind

```bash
/jko:execute MT-2001
/jko:review MT-2001
```

**Repeat for MT-2002, MT-2003...**

---

## Error Scenarios

### Ticket Not Found

```bash
/jko:start MT-9999
```

**Claude:**
- Jira returns 404
- Prompts user to verify ticket key
- Offers to create ticket manually

### No Confluence Access

**Claude:**
- Logs warning
- Continues without Confluence context
- Notes in plan that documentation may be incomplete

### kimi Execution Fails

**Claude:**
- Captures error log
- Analyzes failure
- Offers:
  1. Retry execution
  2. Fix plan and re-execute
  3. Hand off to manual work

### Merge Conflict

**Claude:**
- Detects conflict during kimi execution
- kimi attempts auto-resolve
- If fails, stops and notifies user
- Updates plan with conflict resolution steps

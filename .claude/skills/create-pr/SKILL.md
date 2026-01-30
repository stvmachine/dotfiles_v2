# Create PR Skill

Create a GitHub Pull Request with a standardized description.

## Instructions

1. Get the current branch name and extract the ticket ID (e.g., `MT-9082` from `fix/MT-9082_action_buttons`)

2. Detect the base branch (target for PR):
   ```bash
   # Find the most recent release branch or fall back to master/main
   git branch -r | grep -E 'origin/release/[0-9]+\.[0-9]+\.[0-9]+' | sort -V | tail -1 | xargs
   ```
   If no release branch found, use `origin/master` or `origin/main`.

3. Get the commits on this branch vs the base branch:
   ```bash
   git log <BASE_BRANCH>..HEAD --oneline
   ```

4. Get the changed files:
   ```bash
   git diff <BASE_BRANCH>..HEAD --stat
   ```

5. Generate a PR description using this template:

```markdown
## Summary
[Brief description of what this PR does - infer from commits and changed files]

## Ticket
[TICKET_ID if found, otherwise "N/A"]

## Changes
[List main changes based on commits]

6. Ask the user to confirm or edit the generated description

7. Create the PR using GitHub CLI:
   ```bash
   gh pr create --base <BASE_BRANCH> --title "<TYPE>/<TICKET_ID> Brief title" --body "GENERATED_DESCRIPTION"
   ```

   **Title format**: `<TYPE>/<TICKET_ID> Brief title`

   **Types** (infer from commits and branch name):
   - `feat` - New feature or functionality
   - `fix` - Bug fix
   - `refactor` - Code refactoring without changing behavior
   - `docs` - Documentation only changes
   - `style` - Formatting, missing semicolons, etc (no code change)
   - `test` - Adding or updating tests
   - `chore` - Maintenance tasks, dependencies, configs
   - `perf` - Performance improvements
   - `ci` - CI/CD changes

   **Examples**:
   - `feat/MT-9082 Add user authentication`
   - `fix/MT-9082 Button disabled state styling on Android`
   - `refactor/MT-9082 Migrate to react-hook-form`

## Usage
Invoke with `/create-pr` when ready to create a pull request for the current branch.

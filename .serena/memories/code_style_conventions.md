# Code Style & Conventions

## General Style (from .editorconfig)
- **Indentation**: Tabs (4 spaces width)
- **Line endings**: LF (Unix-style)
- **Charset**: UTF-8
- **Trailing whitespace**: Trimmed
- **Final newline**: Required

### Exceptions
- Markdown (*.md) and YAML (*.yml): 2 spaces, no tabs

## Fish Shell Scripts
- Use `#!/usr/bin/env fish` shebang
- Helper functions for logging:
  - `info` - informational messages
  - `user` - prompts for user input
  - `success` - success messages (green)
  - `abort` - error messages and exit

### Script Structure Pattern
```fish
#!/usr/bin/env fish
#
# Brief description of what the script does.
#
# Examples
#   command-name
#   command-name --flag

# Help handling
if contains -- --help $argv; or contains -- -h $argv
    echo "Usage: ..."
    exit 0
end

# Logging functions
function log
    echo (set_color --bold magenta) "---> $argv" (set_color normal)
end

function log_error
    echo (set_color --bold red) "Error: $argv" (set_color normal) >&2
end

# Main logic...
```

## Git Conventions
- Commits are signed by default (`git commit -s`)
- Force push uses `--force-with-lease` (via `git please` alias)
- Pull uses fast-forward only
- Default branch is `main`
- VS Code is the default editor, diff, and merge tool

### Commit Message Style
Uses conventional commits style (inferred from git-create-pr):
- `feat:` - New features
- `fix:` - Bug fixes
- `refactor:` - Code refactoring
- `docs:` - Documentation
- `style:` - Style changes
- `test:` - Tests
- `chore:` - Maintenance tasks
- `perf:` - Performance improvements
- `ci:` - CI/CD changes

### Branch Naming
Pattern: `type/TICKET-ID_description`
Example: `fix/MT-9082_login_issue`

## File Naming Conventions
- Shell scripts: lowercase with hyphens (`git-create-pr`)
- Symlink sources: `name.symlink` → becomes `~/.name`
- Fish config files: `*.fish` in appropriate directories

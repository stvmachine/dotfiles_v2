# Task Completion Checklist

## Before Completing Any Task

### 1. Code Quality
- [ ] Follow existing code style (tabs for indentation, LF line endings)
- [ ] Keep changes minimal and focused
- [ ] Avoid modifying unrelated code

### 2. For Shell Scripts
- [ ] Include help flag support (`--help`, `-h`)
- [ ] Add descriptive header comments with examples
- [ ] Use consistent logging functions (log, log_error, log_info)
- [ ] Handle errors gracefully with informative messages

### 3. For Fish Configuration
- [ ] Place config files in appropriate directories:
  - `fish/conf.d/` for auto-loaded configuration
  - `fish/completions/` for command completions
  - `fish/functions/` (if needed) or in relevant module dirs
- [ ] Test that fish shell loads without errors

### 4. Testing
- No formal test framework; test manually:
  - Source the fish config: `source ~/.config/fish/config.fish`
  - Run scripts with `--help` to verify help text
  - Test in a fresh fish shell

### 5. Git Workflow
- Use conventional commit messages
- Include ticket ID in branch name if applicable
- Use `git please` for force push (--force-with-lease)

### 6. Documentation
- Update CLAUDE.md if new conventions or patterns are established
- Add memory files for significant learnings

## No Formal CI/CD
This is a personal dotfiles repo without automated testing or linting pipelines.

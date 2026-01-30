# Suggested Commands

## Installation & Setup

### Initial Setup
```bash
git clone https://github.com/stvmachine/dotfiles_v2 ~/.dotfiles
cd ~/.dotfiles
./script/bootstrap.fish
```

### Install Homebrew Packages
```bash
brew bundle --file ~/.dotfiles/macos/Brewfile
```

### Update Dotfiles
```bash
cd ~/.dotfiles
git pull origin main
./script/bootstrap.fish
```

### Set macOS Defaults
```bash
~/.dotfiles/macos/set-defaults.sh
```

## Development Commands

### Git Commands (from bin/)
- `git-create-pr` - Create GitHub PR with standardized description
- `git-create-pr --draft` - Create draft PR
- `git-fetch-merge` - Fetch and merge from remote
- `git-pull-push` - Pull then push
- `git-delete-local-merged` - Clean up merged local branches
- `git-nuke` - Force delete branch locally and remotely
- `git-profile-work` - Switch to work git profile
- `git-profile-personal` - Switch to personal git profile

### Git Aliases (from gitconfig.local.symlink)
- `git co` - checkout
- `git fm` - fetch-merge
- `git please` - push --force-with-lease
- `git commend` - commit --amend --no-edit (signed)
- `git lt` - log tags with decoration
- `git count` - shortlog -sn

### Homebrew
- `brew-bump` - Update brew and upgrade all packages
- `brew-cleanup` - Clean up brew caches

### System Utilities (macOS/Darwin)
Standard Unix commands work, but note:
- `ls` - Use `gls` (GNU ls) if installed via brew for better compatibility
- `sed` - macOS sed differs from GNU sed; use `gsed` if needed
- `find` - Similar; `gfind` available via coreutils

## Fish Shell

### Update Fish Plugins
```fish
fisher update
```

### Reload Fish Config
```fish
source ~/.config/fish/config.fish
```

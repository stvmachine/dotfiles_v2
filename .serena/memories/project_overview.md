# Project Overview: dotfiles

## Purpose
This is a personal dotfiles repository for macOS, forked from [caarlos0/dotfiles.fish](https://github.com/caarlos0/dotfiles.fish). It manages shell configuration, development environment setup, and system preferences.

## Tech Stack
- **Shell**: Fish shell (primary)
- **Prompt**: Starship.rs
- **Package Manager**: Homebrew (for macOS)
- **Plugin Manager**: Fisher (for Fish plugins)
- **Platform**: macOS (Darwin)

## Repository Structure
```
.dotfiles/
├── bin/              # Executable scripts (added to PATH)
├── fish/             # Fish shell configuration
│   ├── conf.d/       # Fish config files (auto-loaded)
│   ├── completions/  # Custom completions
│   └── plugins       # Fisher plugin list
├── git/              # Git configuration
│   ├── conf.d/       # Git-related fish functions
│   └── *.symlink     # Files to be symlinked to ~
├── macos/            # macOS-specific configs
│   └── Brewfile      # Homebrew bundle manifest
├── node/             # Node.js configuration (nvm, pm function)
├── python/           # Python configuration
├── ruby/             # Ruby configuration (rbenv)
├── rust/             # Rust configuration
├── ssh/              # SSH configuration
├── starship/         # Starship prompt configuration
├── script/           # Bootstrap and utility scripts
│   └── bootstrap.fish
└── system/           # System-wide configurations
```

## Symlink Convention
Files ending with `.symlink` are symlinked to the home directory with a `.` prefix:
- `git/gitconfig.local.symlink` → `~/.gitconfig.local`
- `git/gitignore.symlink` → `~/.gitignore`

## Fish Plugins
Managed via Fisher. Current plugins:
- jorgebucaran/autopair.fish
- oh-my-fish/plugin-grc
- jorgebucaran/replay.fish
- jorgebucaran/fisher
- jorgebucaran/nvm.fish
- edc/bass
- sentriz/fish-pipenv
- jethrokuan/fzf

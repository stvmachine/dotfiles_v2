# How Your Dotfiles System Works

## Overview

This is a **modular dotfiles management system** built for the Fish shell. Each component (directory) manages its own configuration independently, and a bootstrap script orchestrates the entire setup.

---

## The "@install.fish (1)" Mystery Explained

When you see `@install.fish (1)` in your terminal, this is **Fish shell's job notation** showing that a script is running as a background job or process. The `(1)` is the job number. This happens because:

1. The bootstrap script runs each `install.fish` script
2. Fish shell tracks these as jobs
3. The `@` prefix indicates it's a job/process identifier

**This is normal behavior** - it's just how Fish displays running processes.

---

## System Architecture

### 1. **Bootstrap Script** (`script/bootstrap.fish`)

This is the **main orchestrator**. It runs once and sets up everything:

```fish
# Key steps:
1. Installs Fisher (Fish plugin manager)
2. Sets up git configuration
3. Creates symlinks for all .symlink files
4. Runs ALL install.fish scripts from each component
5. Sets Fish as default shell
```

**Line 131-135** is where the magic happens:
```fish
for installer in */install.fish
    $installer
        and success $installer
        or abort $installer
end
```

This finds every `install.fish` file in any subdirectory and runs them sequentially.

---

### 2. **Component Structure**

Each component directory (like `starship/`, `git/`, `macos/`) follows this pattern:

```
component-name/
├── install.fish          # Component-specific setup script
├── functions/            # (Optional) Fish functions
├── conf.d/              # (Optional) Fish config snippets
└── *.symlink            # (Optional) Files to symlink to home
```

---

### 3. **How install.fish Scripts Work**

Each `install.fish` script is **idempotent** - you can run it multiple times safely. They typically:

- Set environment variables (`set -Ux`)
- Create abbreviations (`abbr -a`)
- Install dependencies
- Link configuration files
- Set up paths

**Examples:**

**`00-dotfiles/install.fish`** (Core setup):
- Sets `DOTFILES` and `PROJECTS` environment variables
- Adds `bin/` to PATH
- Links all `conf.d/*.fish` files to Fish config
- Sets up function paths

**`starship/install.fish`** (Simple):
- Just sets the `STARSHIP_CONFIG` environment variable

**`git/install.fish`** (Complex):
- Configures git credential helpers
- Sets up delta for better diffs
- Creates many git abbreviations (`g`, `gl`, `gp`, etc.)

**`macos/install.fish`** (Platform-specific):
- Only runs on macOS (`if test (uname) != Darwin`)
- Adds Homebrew paths
- Creates macOS-specific abbreviations

---

### 4. **Symlink System**

Files ending in `.symlink` are automatically linked to your home directory:

- `git/gitconfig.local.symlink` → `~/.gitconfig.local`
- `editorconfig/editorconfig.symlink` → `~/.editorconfig`
- `hyper.js/hyper.js.symlink` → `~/.hyper.js`

This happens in the `install_dotfiles` function (lines 89-105).

---

### 5. **Fish Shell Integration**

**Functions** (`functions/` directories):
- Automatically added to Fish's function path
- Available as commands in your shell
- Example: `git/functions/gpr.fish` → `gpr` command

**Configuration** (`conf.d/` directories):
- Automatically linked to `~/.config/fish/conf.d/`
- Loaded when Fish starts
- Example: `starship/conf.d/starship.fish` → loads Starship prompt

**Abbreviations** (created in `install.fish`):
- Short aliases for common commands
- Example: `abbr -a g 'git'` → type `g` instead of `git`

---

## Your Customizations

Based on what you mentioned, you've edited:

1. **`starship/`** - Your prompt configuration
2. **`hyper.js/`** - Your terminal configuration  
3. **`homebrew/`** - Your package management setup

These are perfect places to customize! Each component is independent.

---

## How to Add a New Component

1. Create a new directory: `mkdir my-component`
2. Create `install.fish`:
   ```fish
   #!/usr/bin/env fish
   # Your setup code here
   ```
3. The bootstrap script will automatically find and run it!

---

## How to Modify Existing Components

Just edit the `install.fish` file in that component's directory. The next time you run `./script/bootstrap.fish`, your changes will be applied.

---

## Key Files to Understand

| File | Purpose |
|------|---------|
| `script/bootstrap.fish` | Main installer - runs everything |
| `00-dotfiles/install.fish` | Core setup - runs first (00 prefix) |
| `*/install.fish` | Component-specific setup scripts |
| `*.symlink` | Files to link to home directory |
| `*/functions/*.fish` | Custom Fish functions |
| `*/conf.d/*.fish` | Fish configuration snippets |

---

## Running the System

**Initial setup:**
```bash
cd ~/.dotfiles
./script/bootstrap.fish
```

**Update after changes:**
```bash
cd ~/.dotfiles
./script/bootstrap.fish  # Safe to run multiple times!
```

---

## Why This Design?

✅ **Modular** - Each component is independent  
✅ **Idempotent** - Safe to run multiple times  
✅ **Organized** - Easy to find and modify configurations  
✅ **Portable** - Works across different machines  
✅ **Version Controlled** - All configs in git  

---

## Troubleshooting

**Q: Why do I see "@install.fish (1)"?**  
A: That's Fish shell's job notation. It's normal - just means a script is running.

**Q: Can I run install.fish scripts individually?**  
A: Yes! `./macos/install.fish` will run just that component.

**Q: What if an install.fish fails?**  
A: The bootstrap script will abort and show which one failed.

**Q: How do I disable a component?**  
A: Rename or remove its `install.fish` file, or add an early `exit` at the top.

---

## Modular vs Monolithic Organization

### How Both Approaches Work

**Both approaches work identically** because of how Fish shell loads configuration:

1. Fish shell loads **ALL** `.fish` files in `~/.config/fish/conf.d/` alphabetically when it starts
2. The bootstrap script (`00-dotfiles/install.fish`) automatically links all `*/conf.d/*.fish` files to `~/.config/fish/conf.d/`
3. Having everything in one file (e.g., `starship/conf.d/starship.fish`) = one file loaded
4. Having separate files (e.g., `node/conf.d/nvm.fish`, `python/conf.d/pyenv.fish`) = multiple files loaded
5. **Result**: Functionally identical - Fish executes all the code regardless of how it's organized

### Why Modular Organization is Better

While both approaches work, modular organization provides significant benefits:

| Aspect | Monolithic (One Big File) | Modular (Separate Components) |
|--------|---------------------------|------------------------------|
| **Finding Config** | Search through 100+ lines | `node/conf.d/nvm.fish` - instant location |
| **Enable/Disable** | Comment out sections | Remove `node/install.fish` or entire `node/` directory |
| **Maintainability** | Edit one huge file, risk conflicts | Edit focused files, clear boundaries |
| **Sharing** | Share entire file | Share just `node/` component |
| **Organization** | Everything mixed together | Each concern separated logically |
| **Testing** | Test everything together | Test one component at a time |
| **Understanding** | Hard to see what belongs where | Clear component boundaries |

### Example: Before and After

**Before (Monolithic)** - Everything in `starship/conf.d/starship.fish`:
```fish
# Starship init
starship init fish | source

# Fish colors
set -g fish_color_command --bold
# ... 20 more color settings

# NVM setup
function nvm ...
# ... 30 lines of NVM config

# Python setup
alias python="python3.12"
# ... more python config

# React Native
set -g ANDROID_HOME ...
# ... more RN config

# Ruby
set PATH $HOME/.rbenv/bin $PATH
# ... more ruby config

# AWS
set -Ux AWS_PROFILE ...
# ... more AWS config
```

**After (Modular)** - Separated into focused components:
```
starship/conf.d/starship.fish    # Just starship init (3 lines)
fish/conf.d/colors.fish          # Just fish colors
node/conf.d/nvm.fish              # Just NVM setup
python/conf.d/aliases.fish        # Just python aliases
react-native/conf.d/android.fish  # Just React Native config
ruby/conf.d/rbenv.fish            # Just Ruby/rbenv config
aws/conf.d/aws.fish               # Just AWS config
```

### When to Create a New Component

Create a new component when:
- You have a **distinct tool or concern** (e.g., Node.js, Python, AWS)
- The configuration is **substantial** (more than a few lines)
- You might want to **enable/disable it** independently
- It's a **logical grouping** that makes sense on its own

Keep it in an existing component when:
- It's a **small addition** to an existing tool
- It's **tightly coupled** to another component
- It's just a **few aliases or settings**

### Component Naming Conventions

- Use **lowercase** with hyphens: `react-native/`, `aws/`, `node/`
- Name after the **primary tool or concern**: `python/`, `ruby/`, `docker/`
- Keep names **descriptive and clear**: `react-native/` not `rn/`

---

## Handling Missing Tools: Defensive Programming

### The Problem

On a new computer setup, not all tools are installed yet. Your dotfiles should **never break** if a tool is missing. Components must gracefully handle missing dependencies.

### The Solution: Always Check Before Using

Every component should check if its dependencies exist before trying to use them. This is called **defensive programming** or **graceful degradation**.

### Pattern 1: Check if Command Exists

Use `command -q` or `command -qs` to check if a command is available:

```fish
# ✅ Good: Check before using
if command -q starship
    starship init fish | source
end

# ❌ Bad: Assumes tool exists (will fail if missing)
starship init fish | source
```

**Examples from your dotfiles:**
- `starship/conf.d/starship.fish` - Checks if starship exists
- `node/conf.d/nvm.fish` - Checks if brew exists before setting up NVM
- `system/install.fish` - Checks for exa, bat, zoxide before creating aliases

### Pattern 2: Check if Directory Exists

Use `test -d` to check if a directory exists:

```fish
# ✅ Good: Check if rbenv is installed
if test -d ~/.rbenv
    status --is-interactive; and ~/.rbenv/bin/rbenv init - fish | source
end

# ❌ Bad: Assumes directory exists
~/.rbenv/bin/rbenv init - fish | source
```

**Examples from your dotfiles:**
- `ruby/install.fish` - Checks if `~/.rbenv` exists before initializing
- `node/conf.d/nvm.fish` - Checks if `~/.nvm` exists before using it

### Pattern 3: Provide Fallbacks

When possible, provide fallback behavior:

```fish
# ✅ Good: Fallback to standard ls if exa not available
if command -qs exa
    abbr -a l 'exa -lh --icons'
else
    abbr -a l 'ls -lAh'  # Fallback
end
```

**Example from your dotfiles:**
- `system/install.fish` - Falls back to `ls` if `exa` isn't installed

### Pattern 4: Silent Failures

Use `2>/dev/null` to suppress error messages when commands might fail:

```fish
# ✅ Good: Silent failure if command doesn't exist
if test -d ~/.nvm
    nvm use default --silent 2>/dev/null
end
```

### What Happens on a New Computer?

1. **Bootstrap runs**: `./script/bootstrap.fish` executes all `install.fish` scripts
2. **Components check**: Each component checks if its tool exists
3. **Graceful skip**: Missing tools are skipped (no errors!)
4. **Available tools work**: Installed tools are configured automatically
5. **Install later**: When you install a tool (e.g., `brew install starship`), restart the shell and it will be configured automatically

**Example: Fresh Mac Setup**

```bash
# Fresh Mac - only has basic tools
./script/bootstrap.fish
# ✅ git/ - works (git comes with macOS)
# ✅ fish/ - works (you installed fish)
# ✅ macos/ - works (macOS-specific)
# ⏭️ starship/ - skipped (starship not installed yet)
# ⏭️ node/ - skipped (brew/nvm not installed yet)
# ⏭️ ruby/ - skipped (rbenv not installed yet)

# Later, install tools:
brew install starship nvm rbenv

# Restart shell - now everything configures automatically!
```

### Best Practices Checklist

When creating a new component, always:

- ✅ **Check if command exists**: `if command -q toolname`
- ✅ **Check if directory exists**: `if test -d /path/to/dir`
- ✅ **Provide fallbacks**: When possible, offer alternative behavior
- ✅ **Silent failures**: Use `2>/dev/null` for commands that might fail
- ✅ **Idempotent**: Safe to run multiple times without errors
- ❌ **Never assume**: Don't assume tools are installed

### Common Fish Shell Checks

```fish
# Check if command exists (quiet)
if command -qs toolname
    # Use toolname
end

# Check if command exists (verbose)
if command -q toolname
    # Use toolname
end

# Check if directory exists
if test -d /path/to/directory
    # Use directory
end

# Check if file exists
if test -f /path/to/file
    # Use file
end

# Check if running interactively
if status --is-interactive
    # Interactive shell code
end
```

---

## Summary

Your dotfiles system is a **modular, component-based configuration manager** where:
- Each directory is a component
- Each component has an `install.fish` that sets it up
- The bootstrap script runs all installers
- Everything is linked and configured automatically
- It's designed to be safe, repeatable, and maintainable
- **Modular organization** makes it easier to find, maintain, and share configurations

The `@install.fish (1)` notation is just Fish shell showing you that scripts are running - completely normal!


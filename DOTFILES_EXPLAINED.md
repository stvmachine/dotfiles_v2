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

## Summary

Your dotfiles system is a **modular, component-based configuration manager** where:
- Each directory is a component
- Each component has an `install.fish` that sets it up
- The bootstrap script runs all installers
- Everything is linked and configured automatically
- It's designed to be safe, repeatable, and maintainable

The `@install.fish (1)` notation is just Fish shell showing you that scripts are running - completely normal!


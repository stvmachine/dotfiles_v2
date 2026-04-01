#!/usr/bin/env fish
# Install AI skills from dotfiles to ~/.claude, ~/.kimi, or other AI tool directories
# Usage: ./install-skills.fish [claude|kimi|all]

set DOTFILES_AI "$HOME/.dotfiles/ai"

function install_skills
    set ai_flavor $argv[1]
    set source_dir "$DOTFILES_AI/$ai_flavor/skills"
    set target_dir "$HOME/.$ai_flavor/skills"
    
    if not test -d "$source_dir"
        echo "❌ Source directory not found: $source_dir"
        return 1
    end
    
    echo "📦 Installing $ai_flavor skills..."
    echo "   From: $source_dir"
    echo "   To:   $target_dir"
    
    # Create target directory if it doesn't exist
    mkdir -p "$target_dir"
    
    # Count skills
    set skill_count (count $source_dir/*)
    if test $skill_count -eq 0
        echo "⚠️  No skills found in $source_dir"
        return 0
    end
    
    # Copy each skill
    set installed 0
    for skill_path in $source_dir/*
        if test -d "$skill_path"
            set skill_name (basename "$skill_path")
            set target_skill "$target_dir/$skill_name"
            
            # Remove existing skill if present
            if test -d "$target_skill"
                rm -rf "$target_skill"
                echo "   🔄 Updated: $skill_name"
            else
                echo "   ✨ New: $skill_name"
            end
            
            cp -r "$skill_path" "$target_skill"
            set installed (math $installed + 1)
        end
    end
    
    echo "✅ Installed $installed $ai_flavor skills"
    return 0
end

# Main
set flavor $argv[1]

switch "$flavor"
    case claude
        install_skills claude
    case kimi
        install_skills kimi
    case all ""
        install_skills claude
        install_skills kimi
        # Add more AI flavors here as needed
        # install_skills cursor
        # install_skills codex
    case '*'
        echo "Usage: $argv[0] [claude|kimi|all]"
        echo ""
        echo "Install AI skills from dotfiles to the specified AI tool directory."
        echo ""
        echo "Arguments:"
        echo "  claude  - Install Claude skills to ~/.claude/skills/"
        echo "  kimi    - Install Kimi skills to ~/.kimi/skills/"
        echo "  all     - Install all AI skills (default)"
        exit 1
end

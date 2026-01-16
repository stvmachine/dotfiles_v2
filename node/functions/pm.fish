function pm -d "Run the package manager specified in package.json"
    # Check for --help flag
    if contains -- --help $argv; or contains -- -h $argv
        echo "Usage: pm [command] [args...]"
        echo ""
        echo "Runs the package manager specified in package.json's packageManager field."
        echo "Falls back to npm if no packageManager is specified."
        echo ""
        echo "Supported package managers: npm, yarn, pnpm, bun"
        echo ""
        echo "Examples:"
        echo "  pm install           # Runs 'npm install' or 'pnpm install' etc."
        echo "  pm add lodash        # Runs 'npm add lodash' or 'pnpm add lodash' etc."
        echo "  pm run build         # Runs the build script"
        echo "  pm                   # Shows which package manager would be used"
        return 0
    end

    # Detect package manager from package.json
    set -l pkg_manager npm

    if test -f package.json
        # Try to extract packageManager field using grep and string manipulation
        set -l pm_field (grep -o '"packageManager"[[:space:]]*:[[:space:]]*"[^"]*"' package.json 2>/dev/null | head -1)
        
        if test -n "$pm_field"
            # Extract the value (e.g., "pnpm@8.0.0" -> "pnpm")
            set -l pm_value (echo $pm_field | string replace -r '.*"packageManager"[[:space:]]*:[[:space:]]*"([^@"]+).*' '$1')
            
            if test -n "$pm_value"
                switch $pm_value
                    case npm yarn pnpm bun
                        set pkg_manager $pm_value
                end
            end
        else
            # Fallback: detect by lock file
            if test -f pnpm-lock.yaml
                set pkg_manager pnpm
            else if test -f yarn.lock
                set pkg_manager yarn
            else if test -f bun.lockb
                set pkg_manager bun
            else if test -f package-lock.json
                set pkg_manager npm
            end
        end
    end

    # If no arguments, just show which package manager would be used
    if test (count $argv) -eq 0
        echo "Using: $pkg_manager"
        return 0
    end

    # Run the package manager with all arguments
    command $pkg_manager $argv
end

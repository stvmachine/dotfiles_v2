# Auto-activate the nearest Python virtualenv when changing directories.
# Only auto-deactivate environments activated by this hook.

function __auto_venv_find --description 'Find nearest .venv directory'
    set -l dir $PWD

    while true
        if test -f "$dir/.venv/bin/activate.fish"
            echo "$dir/.venv"
            return 0
        end

        if test "$dir" = "/"
            return 1
        end

        set dir (path dirname "$dir")
    end
end

function __auto_venv_on_pwd --on-variable PWD --description 'Auto activate/deactivate venv'
    status --is-interactive; or return

    set -l target_venv (__auto_venv_find)

    if set -q target_venv[1]
        if test "$VIRTUAL_ENV" != "$target_venv[1]"
            if set -q __auto_venv_active[1]
                if functions -q deactivate
                    deactivate
                end
            end

            source "$target_venv[1]/bin/activate.fish"
            set -g __auto_venv_active "$target_venv[1]"
        end
        return
    end

    if set -q __auto_venv_active[1]
        if test "$VIRTUAL_ENV" = "$__auto_venv_active"
            if functions -q deactivate
                deactivate
            end
        end
        set -e __auto_venv_active
    end
end

# Run once for the initial shell directory.
__auto_venv_on_pwd

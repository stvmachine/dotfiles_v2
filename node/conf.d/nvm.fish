# NVM auto-switching for Fish shell.
if functions -q nvm
    set -q nvm_data; or set -gx nvm_data $HOME/.nvm/versions/node
    set -q nvm_mirror; or set -gx nvm_mirror https://nodejs.org/dist

    function __nvm_sync_path_links --description 'Refresh ~/bin links for apps that expect node on PATH'
        if not test -d ~/bin
            mkdir ~/bin
            fish_add_path ~/bin
        end

        rm -f ~/bin/node ~/bin/npm
        ln -s (command -s node) ~/bin/node
        ln -s (command -s npm) ~/bin/npm
    end

    function __nvm_auto_use --on-variable PWD --description 'Auto-switch Node from .nvmrc or .node-version'
        set -l version_file
        for candidate in .nvmrc .node-version
            set version_file (_nvm_find_up $PWD $candidate)
            if test -n "$version_file"
                break
            end
        end

        if test -n "$version_file"
            read -l requested_version < $version_file
            nvm use $requested_version --silent 2>/dev/null
            or nvm install $requested_version

            __nvm_sync_path_links
        else if set -q nvm_default_version
            if test (nvm current) != "$nvm_default_version"
                nvm use default --silent
                __nvm_sync_path_links
            end
        end
    end

    __nvm_auto_use
end

set -Ux NODE_OPTIONS "--max-old-space-size=4096"

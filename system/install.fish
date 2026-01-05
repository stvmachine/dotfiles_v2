#!/usr/bin/env fish
abbr -a less 'less -r'

# fzf configuration
if command -qs fzf
    # Use fd for fzf (faster than find)
    set -gx FZF_DEFAULT_COMMAND 'fd --type f --hidden --follow --exclude .git'

    # fzf options
    set -gx FZF_DEFAULT_OPTS '
        --height 40%
        --layout=reverse
        --border
        --preview "bat --style=numbers --color=always {} || cat {}"
        --preview-window right:60%:wrap
        --bind "ctrl-y:execute-silent(echo {} | pbcopy)+abort"
    '

    # Use fzf for better history search
    if command -qs fzf
        function history-search
            history | fzf --tac | read -l command
            if test $command
                commandline -rb $command
            end
        end

        function fish_user_key_bindings
            bind \cr history-search
        end
    end
end


#!/usr/bin/env fish
# Ruby and rbenv setup

# Only runs if rbenv is installed
if test -d ~/.rbenv
    set -g RBENV_ROOT $HOME/.rbenv
    fish_add_path $RBENV_ROOT/bin 2>/dev/null; or true

    # Init rbenv with fish
    status --is-interactive; and ~/.rbenv/bin/rbenv init - fish | source 2>/dev/null; or true
end

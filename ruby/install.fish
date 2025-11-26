#!/usr/bin/env fish
# Ruby and rbenv setup

# Ruby paths
set PATH $HOME/.rbenv/bin $PATH
set PATH $HOME/.rbenv/shims $PATH

# Init rbenv with fish. Source: https://github.com/rbenv/rbenv#basic-git-checkout
if test -d ~/.rbenv
    status --is-interactive; and ~/.rbenv/bin/rbenv init - fish | source
    rbenv rehash >/dev/null ^&1
end


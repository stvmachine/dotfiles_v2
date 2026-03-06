# Only runs if rbenv is installed
if command -q rbenv
    set -gx RBENV_ROOT $HOME/.rbenv

    # Init rbenv with fish
    status --is-interactive; and rbenv init - fish | source 2>/dev/null; or true
end

# Trigger 'rbenv install x.y.z' if .ruby-version exists in the folder
function __check_ruby_version --on-variable PWD --description 'Do rbenv stuff'
    if test -f .ruby-version
        yes no | rbenv install (cat .ruby-version)
    end
end

# Install ruby version if it's necessary
__check_ruby_version

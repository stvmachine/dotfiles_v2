#!/usr/bin/env fish
if command -q starship
    starship init fish | source
end

# Fish syntax highlighting
set -g fish_color_autosuggestion '555'  'brblack'
set -g fish_color_cancel -r
set -g fish_color_command --bold
set -g fish_color_comment red
set -g fish_color_cwd green
set -g fish_color_cwd_root red
set -g fish_color_end brmagenta
set -g fish_color_error brred
set -g fish_color_escape 'bryellow'  '--bold'
set -g fish_color_history_current --bold
set -g fish_color_host normal
set -g fish_color_match --background=brblue
set -g fish_color_normal normal
set -g fish_color_operator bryellow
set -g fish_color_param cyan
set -g fish_color_quote yellow
set -g fish_color_redirection brblue
set -g fish_color_search_match 'bryellow'  '--background=brblack'
set -g fish_color_selection 'white'  '--bold'  '--background=brblack'
set -g fish_color_user brgreen
set -g fish_color_valid_path --underline

# ------------------------ NVM ----------------------------------------

function nvm
   bass source (brew --prefix nvm)/nvm.sh --no-use ';' nvm $argv
end

set -x NVM_DIR ~/.nvm
nvm use default --silent

# Trigger 'nvm use' if .nvmrc exists in the folder
function __check_nvm --on-variable PWD --description 'Do nvm stuff'
  if test -f .nvmrc
    set node_version (nvm version)
    set nvmrc_node_version (nvm version (cat .nvmrc))

    if [ $nvmrc_node_version = "N/A" ]
      nvm install
    else if [ $nvmrc_node_version != $node_version ]
      nvm use
    end

    # Testing if ~/bin folder exists
    if test -d ~/bin
      echo "Dir ~/bin exists"
    else 
      mkdir ~/bin
      fish_add_path ~/bin
    end
    
    # link node to usr/local/bin for apps that doesn't work well with nvm as xcode
    rm -f ~/bin/node
    rm -f ~/bin/npm
    ln -s "$(which node)" ~/bin/node
    ln -s "$(which npm)" ~/bin/npm
  end
end

__check_nvm


# Ensure user-installed binaries take precedence
fish_add_path /usr/local/bin:$PATH

# ------------------------ PYTHON ----------------------------------------
# Pyenv
set -g PYENV_ROOT $HOME/.pyenv
fish_add_path $PYENV_ROOT/bin:$PATH
alias brew="env PATH=(string replace (pyenv root)/shims '' \"\$PATH\") brew"

# Assigning python3 as python through an alias
alias python="/usr/bin/python3"

# If everything fails, run this in the command line to make it works 'python' and 'pip' commands
eval "$(pyenv init --path)"

# set if your term supports `pipenv shell --fancy`
set pipenv_fish_fancy yes

# ------------------------ REACT NATIVE ----------------------------------------
# Android sdk tools
# set -g ANDROID_HOME $HOME/Library/Android/sdk
# set -g ANDROID_SDK_ROOT $HOME/Library/Android/sdk
# fish_add_path $ANDROID_HOME/tools
# fish_add_path $ANDROID_HOME/tools/bin
# fish_add_path $ANDROID_HOME/emulator
# fish_add_path $ANDROID_HOME/platform-tools

# React Native: For not shake on RN to access debug options
# alias rnmenu "adb shell input keyevent 82"

# ------------------------- RUBY ---------------------------------------
# Trigger 'rbenv install x.y.z' if .ruby-version exists in the folder
# function __check_ruby_version --on-variable PWD --description 'Do rbenv stuff'
#   if test -f .ruby-version
#     yes no | rbenv install (cat .ruby-version)
#   end
# end

# Ruby
# set PATH $HOME/.rbenv/bin $PATH
# set PATH $HOME/.rbenv/shims $PATH

# Init rbven with fish. Source: https://github.com/rbenv/rbenv#basic-git-checkout
# status --is-interactive; and ~/.rbenv/bin/rbenv init - fish | source

# If that above doesn't start rbenv, try this command instead
# rbenv rehash >/dev/null ^&1

# Install ruby version if it's necessary
# __check_ruby_version

# Fastlane 
# fish_add_path "$HOME/.fastlane/bin:$PATH"

# Rover: Apollo Graphql Tool
# set PATH $HOME/.rover/bin $PATH


# Rust
# . "$HOME/.cargo/env"
# source "/Users/estvmachine/.rover/env"


## Google Cloud SDK
source "$(brew --prefix)/share/google-cloud-sdk/path.fish.inc"
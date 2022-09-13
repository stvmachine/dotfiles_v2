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


# Originally my bash_profile

# ----------- NVM ------
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

    # Link node to usr/bin for applications that are not compatible with nvm like xcode
    # https://gist.github.com/MeLlamoPablo/0abcc150c10911047fd9e5041b105c34
    sudo rm -f /usr/bin/node
    sudo rm -f /usr/bin/npm
    sudo ln -s $(which node) /usr/bin/
    sudo ln -s $(which npm) /usr/bin/

    if [ $nvmrc_node_version = "N/A" ]
      nvm install
    else if [ $nvmrc_node_version != $node_version ]
      nvm use
    end
  end
end

__check_nvm

# Ensure user-installed binaries take precedence
fish_add_path /usr/local/bin:$PATH

# --------- Python -----
# Pyenv
# set -g PYENV_ROOT $HOME/.pyenv
# fish_add_path $PYENV_ROOT/bin:$PATH
# if command -v pyenv 1>/dev/null 2>&1; then eval "$(pyenv init -)"; fi
# if command -v pyenv 1>/dev/null 2>&1; then eval "$(pyenv virtualenv-init -)"; fi

# ----------- React Native ------
# Android sdk tools
set -g ANDROID_HOME $HOME/Library/Android/sdk
set -g ANDROID_SDK_ROOT $HOME/Library/Android/sdk
fish_add_path $ANDROID_HOME/tools
fish_add_path $ANDROID_HOME/tools/bin
fish_add_path $ANDROID_HOME/emulator
fish_add_path $ANDROID_HOME/platform-tools

# React Native: For not shake on RN to access debug options
alias rnmenu "adb shell input keyevent 82"

# Fastlane
set -x PATH $HOME/.rbenv/bin $PATH
set --universal fish_user_paths $fish_user_paths $HOME/.rbenv/shims
if which rbenv > /dev/null 
  eval "$(rbenv init - | source)"
end
# fish_add_path "$HOME/.fastlane/bin:$PATH"
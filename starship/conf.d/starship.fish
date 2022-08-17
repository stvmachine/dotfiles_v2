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
# set -g ANDROID_HOME $HOME/Library/Android/sdk
# fish_add_path $PATH:$ANDROID_HOME/tools
# fish_add_path $PATH:$ANDROID_HOME/tools/bin
# fish_add_path $PATH:$ANDROID_HOME/platform-tools

# React Native: For not shake on RN to access debug options
# alias rnmenu "adb shell input keyevent 82"

# Fastlane
# if which rbenv > /dev/null; then eval "$(rbenv init -)"; fi
# fish_add_path "$HOME/.fastlane/bin:$PATH"
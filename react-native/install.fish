#!/usr/bin/env fish
# React Native and Android SDK setup

set -g ANDROID_HOME $HOME/Library/Android/sdk
set -g ANDROID_SDK_ROOT $HOME/Library/Android/sdk
fish_add_path $ANDROID_HOME/tools
fish_add_path $ANDROID_HOME/tools/bin
fish_add_path $ANDROID_HOME/emulator
fish_add_path $ANDROID_HOME/platform-tools


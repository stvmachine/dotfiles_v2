#!/usr/bin/env fish
# React Native and Android SDK setup

set -g ANDROID_HOME $HOME/Library/Android/sdk
set -g ANDROID_SDK_ROOT $HOME/Library/Android/sdk

# Only add paths if Android SDK is installed
if test -d $ANDROID_HOME
	fish_add_path $ANDROID_HOME/tools 2>/dev/null; or true
	fish_add_path $ANDROID_HOME/tools/bin 2>/dev/null; or true
	fish_add_path $ANDROID_HOME/emulator 2>/dev/null; or true
	fish_add_path $ANDROID_HOME/platform-tools 2>/dev/null; or true
end


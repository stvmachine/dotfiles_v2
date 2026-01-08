#!/usr/bin/env fish
# React Native and Android SDK setup

set -gx JAVA_HOME=$HOME/Library/Java/JavaVirtualMachines/zulu-17.jdk/Contents/Home
set -gx ANDROID_HOME $HOME/Library/Android/sdk
set -gx ANDROID_SDK_ROOT $HOME/Library/Android/sdk

# Only add paths if Android SDK is installed
if test -d $ANDROID_HOME
	set -gx PATH $ANDROID_HOME/tools $PATH 2>/dev/null; or true
	set -gx PATH $ANDROID_HOME/tools/bin $PATH 2>/dev/null; or true
	set -gx PATH $ANDROID_HOME/emulator $PATH 2>/dev/null; or true
	set -gx PATH $ANDROID_HOME/platform-tools $PATH 2>/dev/null; or true
end


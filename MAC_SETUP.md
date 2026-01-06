# Mac OS X setup

Facing the setup of a new machine (or the need to reinstall after a fresh OS install or the like), here's a very brief and basic list of the usual suspects, related to the setup of a mac computer to work with (mostly related to a scripting languages context).

## Homebrew & Cask

The package manager is the default first thing I always install. Simply following the default steps. Homebrew should download and install the Command Line Tools for Xcode automatically, but if it doesn't work, you can install them manually:

```bash
xcode-select --install
```

Then install Homebrew and tap the cask upgrade repository:

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
brew tap buo/cask-upgrade
```

Homebrew Cask is implemented as part of Homebrew now, so we're cask-enabled and ready from the start for our tapping. Finally, `brew-cask-upgrade` provides upgrade-like capabilities to cask, and we're all set.

If you need to combine or update your own Brewfile, you can check the [following instructions](https://gist.github.com/stvmachine/55e78bba6fa123f56e62b8ad14c3aaf0).

## Mac App Store

If some previously purchased software from the Mac App Store needs to be included, we can use `mas` to ease the installs.

```bash
brew install mas
```

## My curated list of apps (and all that jazz)

Once we have `homebrew`, `cask` (and `mas` if needed) we're ready to go (and yes, these lists might be scripted for some automation to install all, take this as just a curated set):

```
# Updating homebrew and getting cask and mas.
tap "homebrew/core"
tap "homebrew/bundle"
tap "homebrew/services"
tap "homebrew/cask"
tap "buo/cask-upgrade"
tap "homebrew/cask-fonts"
tap "homebrew/cask-versions"
brew "mas"

# Recommended for the repo
brew "curl"
brew "git"
brew "tar"
brew "fish"
brew "git-delta"
brew "fzf"
brew "gh"
brew "grc"
brew "kubectx"
brew "starship"
brew "fd"
brew "bat"
```

General apps

```
# Text editors/IDEs
cask "hyper"
cask "visual-studio-code"

# Dev tools
brew "rbenv"
brew "ruby"
brew "yarn"
cask "docker"

# Productivity
cask "alfred"
cask "spectacle"

# Notes
cask "obsidian"

# Common apps
cask "calibre"
cask "spotify"
cask "vlc"

# DB managers
cask "dbeaver-community"
cask "mongodb-compass"

# API development
cask "insomnia"
# cask "postman"

# Browsers
cask "brave-browser"
cask "firefox-developer-edition"

# Messaging and videoconference
cask "rambox"
cask "slack"
cask "zoom"
```

Already purchased apps from app store. It's necessary to sign in through the app store in beforehand. In some newer versions of Mac, "mas" is not able to do it automatically.

```
# Install apps already purchased in the mac app store. Not for everyone
# Be sure, to login into the app store in beforehand

# Amphetamine
# mas install 937984704

# Xcode. Will take forever to download, yes. Not needed for everyone.
# mas install 497799835
```

## Acknowledge

Thanks to alexramirez: <https://github.com/alexramirez/mac-setup>

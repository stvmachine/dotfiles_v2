Forked from [Caarlos0 dotfiles](https://github.com/caarlos0/dotfiles.fish)

## Installation

### Dependencies

First, make sure you have all those things installed:

- `git`: to clone the repo
- `curl`: to download some stuff
- `tar`: to extract downloaded stuff
- `fish`: the shell
- `sudo`: some configs may need that

### Install

Then, run these steps:

```console
git clone https://github.com/stvmachine/dotfiles_v2 ~/.dotfiles
cd ~/.dotfiles
./script/bootstrap.fish
```

### Mac brew install

Run brew bundle from macos folder

```console
cd macos
brew bundle
```

> All changed files will be backed up with a `.backup` suffix.

#### Update

To update, you just need to `git pull` and run the bootstrap script again:

```console
cd ~/.dotfiles
git pull origin master
./script/bootstrap.fish
```

## Revert

Reverting is not totally automated, but it pretty much consists in removing
the fish config and dotfiles folder, as well as moving back some config files.

```console
rm -rf ~/.dotfiles $__fish_config_dir
```

The bootstrap script would have created a bunch of symlinks that will now be broken.
You will have to investigate those manually.
In cases a file already existed, the boostrap script should have created a `.backup` file with the same name.

## Recommended Software

All tools below are compatible with Fish shell and Starship prompt:

- [`bat`](https://github.com/sharkdp/bat) a cat(1) clone with wings;
- [`fzf`](https://github.com/junegunn/fzf) for a fuzzy-finder (with Fish integration);
- [`gh`](https://github.com/cli/cli) for more GitHub integration with the terminal;
- [`grc`](https://github.com/garabik/grc) to colorize command's outputs;
- [`starship.rs`](https://starship.rs) the prompt we are using (Fish is the shell);

### On Mac

Follow the instructions [`here`](MAC_SETUP.md).

### On Ubuntu

```console
sh -c "$(curl -fsSL https://starship.rs/install.sh)"
sudo apt install fish grc fzf
# TODO: install delta, kubectx
```

## macOS defaults

You use it by running:

```console
~/.dotfiles/macos/set-defaults.sh
```

And logging out and in again or restart.

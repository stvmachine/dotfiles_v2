#!/usr/bin/env fish
set -Ux STARSHIP_CONFIG $DOTFILES/starship/config.toml

# Link the starship config file
mkdir -p ~/.config
ln -sf $DOTFILES/starship/config.toml ~/.config/starship.toml

#!/usr/bin/env fish
set -Ux STARSHIP_CONFIG $DOTFILES/starship/config.toml

# Link the starship config file
link_file $DOTFILES/starship/config.toml ~/.config/starship.toml backup

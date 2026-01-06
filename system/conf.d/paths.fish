# System PATH additions
fish_add_path /opt/homebrew/bin $PATH
fish_add_path --prepend /usr/local/bin
fish_add_path $HOME/.local/bin

# Load credentials
if test -f $HOME/.dotfiles/credentials/npm.fish
    source $HOME/.dotfiles/credentials/npm.fish
end
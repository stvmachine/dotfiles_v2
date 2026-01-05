#!/usr/bin/env fish
# Python and Pyenv setup

# Pyenv configuration - only runs if pyenv is installed
if test -d ~/.pyenv
	set -g PYENV_ROOT $HOME/.pyenv
	fish_add_path $PYENV_ROOT/bin 2>/dev/null; or true
	
	# Init pyenv with fish
	status --is-interactive; and ~/.pyenv/bin/pyenv init - fish | source 2>/dev/null; or true
	
	# Prevent pyenv shims from interfering with brew
	alias brew="env PATH=(string replace (pyenv root)/shims '' \"\$PATH\") brew"
end

# Set if your term supports `pipenv shell --fancy`
if command -qs pipenv
	set -g pipenv_fish_fancy yes 2>/dev/null; or true
end


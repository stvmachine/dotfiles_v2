#!/usr/bin/env fish

# Default editor
git config --global core.editor zed

# Don't ask ssh password all the time
switch (uname)
case Darwin
	git config --global credential.helper osxkeychain
case '*'
	git config --global credential.helper cache
end

# Functions for dynamic git commands
function gm -d "Switch to main branch"
	git switch (git main-branch) $argv
end

function gms -d "Switch to main branch and sync"
	git switch (git main-branch)
	and git sync
end

function egms -d "Open editor, switch to main branch and sync"
	$EDITOR .
	and git switch (git main-branch)
	and git sync
end

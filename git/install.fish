#!/usr/bin/env fish

# Don't ask ssh password all the time
switch (uname)
case Darwin
	git config --global credential.helper osxkeychain
case '*'
	git config --global credential.helper cache
end

# better diffs
if command -qs delta
	git config --global core.pager delta
	git config --global interactive.diffFilter 'delta --color-only'
	git config --global delta.line-numbers true
	git config --global delta.decorations true
end

abbr -a g 'git'
abbr -a gl 'git pull --prune'
abbr -a glg "git log --graph --decorate --oneline --abbrev-commit"
abbr -a glga "glg --all"
abbr -a gp 'git push origin HEAD'
abbr -a gpa 'git push origin --all'
abbr -a gd 'git diff'
abbr -a gc 'git commit -s'
abbr -a gca 'git commit -sa'
abbr -a gco 'git checkout'
abbr -a gb 'git branch -v'
abbr -a ga 'git add'
abbr -a gaa 'git add -A'
abbr -a gcm 'git commit -sm'
abbr -a gcam 'git commit -sam'
abbr -a gs 'git status -sb'
abbr -a glnext 'git log --oneline (git describe --tags --abbrev=0 @^)..@'
abbr -a gw 'git switch'
abbr -a gwc 'git switch -c'

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

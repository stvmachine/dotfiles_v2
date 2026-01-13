# Git abbreviations
abbr -a -g g 'git'
abbr -a -g gl 'git pull --prune'
abbr -a -g glg "git log --graph --decorate --oneline --abbrev-commit"
abbr -a -g glga "glg --all"
abbr -a -g gp 'git push origin HEAD'
abbr -a -g gpa 'git push origin --all'
abbr -a -g gd 'git diff'
abbr -a -g gc 'git commit -s'
abbr -a -g gca 'git commit -sa'
abbr -a -g gco 'git checkout'
abbr -a -g gb 'git branch -v'
abbr -a -g ga 'git add'
abbr -a -g gaa 'git add -A'
abbr -a -g gcm 'git commit -sm'
abbr -a -g gcam 'git commit -sam'
abbr -a -g gs 'git status -sb'
abbr -a -g glnext 'git log --oneline (git describe --tags --abbrev=0 @^)..@'
abbr -a -g gw 'git switch'
abbr -a -g gwc 'git switch -c'
abbr -a -g personal 'git config --local user.name "stvmachine"; and git config --local user.email "campos.esteban@gmail.com"'

# Git profile switching functions for SSH key management
function git-profile-personal -d "Switch to personal git profile (stvmachine)"
	git config --local user.name "stvmachine"
	git config --local user.email "campos.esteban@gmail.com"

	# Update existing remotes to use personal SSH key (github-personal)
	for remote in (git remote)
		set remote_url (git remote get-url $remote)
		
		# Handle SSH URLs: git@github.com:user/repo -> git@github-personal:user/repo
		if string match -q "git@github.com:*" $remote_url
			set new_url (string replace "git@github.com:" "git@github-personal:" $remote_url)
			git remote set-url $remote $new_url
			echo "Updated remote '$remote': $new_url"
		# Handle HTTPS URLs: https://github.com/user/repo -> git@github-personal:user/repo
		else if string match -q "https://github.com/*" $remote_url
			set repo_path (string replace "https://github.com/" "" $remote_url)
			set new_url "git@github-personal:$repo_path"
			git remote set-url $remote $new_url
			echo "Updated remote '$remote': $new_url (converted HTTPS to SSH)"
		# Skip if already using github-personal
		else if string match -q "*github-personal*" $remote_url
			echo "Remote '$remote' already uses github-personal"
		end
	end

	echo "Switched to personal git profile: stvmachine <campos.esteban@gmail.com>"
end

function git-profile-work -d "Switch to work git profile (updates remotes to use github-work SSH key)"
	# Note: Git user.name and user.email should be set manually for work profile
	# This function only updates remote URLs to use the work SSH key

	# Update existing remotes to use work SSH key (github-work)
	for remote in (git remote)
		set remote_url (git remote get-url $remote)
		
		# Handle github-personal SSH URLs: git@github-personal:user/repo -> git@github-work:user/repo
		if string match -q "git@github-personal:*" $remote_url
			set new_url (string replace "git@github-personal:" "git@github-work:" $remote_url)
			git remote set-url $remote $new_url
			echo "Updated remote '$remote': $new_url"
		# Handle github.com SSH URLs: git@github.com:user/repo -> git@github-work:user/repo
		else if string match -q "git@github.com:*" $remote_url
			set new_url (string replace "git@github.com:" "git@github-work:" $remote_url)
			git remote set-url $remote $new_url
			echo "Updated remote '$remote': $new_url"
		# Handle HTTPS URLs: https://github.com/user/repo -> git@github-work:user/repo
		else if string match -q "https://github.com/*" $remote_url
			set repo_path (string replace "https://github.com/" "" $remote_url)
			set new_url "git@github-work:$repo_path"
			git remote set-url $remote $new_url
			echo "Updated remote '$remote': $new_url (converted HTTPS to SSH)"
		# Skip if already using github-work
		else if string match -q "*github-work*" $remote_url
			echo "Remote '$remote' already uses github-work"
		end
	end

	echo "Updated remotes to use work SSH key (github-work)"
	echo "Remember to set git config manually: git config user.name 'Your Name' && git config user.email 'your.email@work.com'"
end
#!/usr/bin/env fish
#
# bootstrap installs things.

set DOTFILES_ROOT (pwd -P)

function info
	echo [(set_color --bold) ' .. ' (set_color normal)] $argv
end

function user
	echo [(set_color --bold) ' ?? ' (set_color normal)] $argv
end

function success
	echo [(set_color --bold green) ' OK ' (set_color normal)] $argv
end

function abort
	echo [(set_color --bold yellow) ABRT (set_color normal)] $argv
	exit 1
end

function on_exit -p %self
	if not contains $argv[3] 0
		echo [(set_color --bold red) FAIL (set_color normal)] "Couldn't setup dotfiles, please open an issue at https://github.com/caarlos0/dotfiles"
	end
end

function setup_gitconfig
	set managed (git config --global --get dotfiles.managed)
	# if there is no user.email, we'll assume it's a new machine/setup and ask it
	if test -z (git config --global --get user.email)
		user 'What is your github author name?'
		read user_name
		user 'What is your github author email?'
		read user_email

		test -n $user_name
			or echo "please inform the git author name"
		test -n $user_email
			or abort "please inform the git author email"

		git config --global user.name $user_name
			and git config --global user.email $user_email
			or abort 'failed to setup git user name and email'
	else if test "$managed" != "true"
		# if user.email exists, let's check for dotfiles.managed config. If it is
		# not true, we'll backup the gitconfig file and set previous user.email and
		# user.name in the new one
		set user_name (git config --global --get user.name)
			and set user_email (git config --global --get user.email)
			and mv ~/.gitconfig ~/.gitconfig.backup
			and git config --global user.name $user_name
			and git config --global user.email $user_email
			and success "moved ~/.gitconfig to ~/.gitconfig.backup"
			or abort 'failed to setup git user name and email'
	else
		# otherwise this gitconfig was already made by the dotfiles
		info "already managed by dotfiles"
	end
	# include the gitconfig.local file
	# finally make git knows this is a managed config already, preventing later
	# overrides by this script
	git config --global include.path ~/.gitconfig.local
		and git config --global dotfiles.managed true
		or abort 'failed to setup git'
end

function link_file -d "links a file keeping a backup"
	echo $argv | read -l old new backup
	if test -e $new
		set newf (readlink $new)
		if test "$newf" = "$old"
			success "skipped $old"
			return
		else
			mv $new $new.$backup
				and success moved $new to $new.$backup
				or abort "failed to backup $new to $new.$backup"
		end
	end
	mkdir -p (dirname $new)
		and ln -sf $old $new
		and success "linked $old to $new"
		or abort "could not link $old to $new"
end

function install_dotfiles
	for src in $DOTFILES_ROOT/*/*.symlink
		link_file $src $HOME/.(basename $src .symlink) backup
			or abort 'failed to link config file'
	end

	link_file $DOTFILES_ROOT/fish/plugins $__fish_config_dir/fish_plugins backup
		or abort plugins
	link_file $DOTFILES_ROOT/system/bat.config $HOME/.config/bat/config backup
		or abort bat
	link_file $DOTFILES_ROOT/ssh/config.dotfiles $HOME/.ssh/config.dotfiles backup
		or abort ssh-config
	link_file $DOTFILES_ROOT/ssh/rc $HOME/.ssh/rc backup
		or abort ssh-rc
end

curl -sL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish | source && fisher install jorgebucaran/fisher
	and success 'fisher'
	or abort 'fisher'

setup_gitconfig
	and success 'gitconfig'
	or abort 'gitconfig'

install_dotfiles
	and success 'dotfiles'
	or abort 'dotfiles'

fisher update
	and success 'plugins'
	or abort 'plugins'

mkdir -p $__fish_config_dir/completions/
	and success 'completions'
	or abort 'completions'

for installer in */install.fish
	$installer
		and success $installer
		or abort $installer
end

# Get the absolute path to fish
set fish_path (command -v fish)
set fish_abs_path (realpath $fish_path 2>/dev/null; or echo $fish_path)

# Add fish to /etc/shells if not already there
if not grep -q "^$fish_abs_path\$" /etc/shells
	info "Adding fish to /etc/shells (requires sudo password)..."
	echo $fish_abs_path | sudo tee -a /etc/shells > /dev/null
		and success 'added fish to /etc/shells'
		or abort 'failed to add fish to /etc/shells'
end

# Check if fish is already the default shell
# On macOS, check the actual login shell using dscl
switch (uname)
case Darwin
	set current_shell (dscl . -read /Users/(whoami) UserShell 2>/dev/null | sed 's/UserShell: //')
case '*'
	# On Linux, check /etc/passwd or use getent
	set current_shell (getent passwd (whoami) 2>/dev/null | cut -d: -f7; or echo $SHELL)
end

if test -z "$current_shell"
	set current_shell $SHELL
end

set current_shell_resolved (realpath $current_shell 2>/dev/null; or echo $current_shell)

if test "$fish_abs_path" = "$current_shell_resolved"
	success "fish is already the default shell"
	success 'dotfiles installed/updated!'
	exit 0
end

# Change default shell to fish
info "Changing default shell to fish (requires password)..."
info "You may be prompted for your password"
chsh -s $fish_abs_path
	and success "set fish as the default shell"
	or begin
		user "Failed to change shell automatically. Please run manually:"
		echo "  chsh -s $fish_abs_path"
		abort 'could not set fish as default shell'
	end

success 'dotfiles installed/updated!'

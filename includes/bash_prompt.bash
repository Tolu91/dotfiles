#
# Clean and minimalistic Bash prompt
# Author: Artem Sapegin, sapegin.me
# 
# Inspired by: https://github.com/sindresorhus/pure & https://github.com/dreadatour/dotfiles/blob/master/.bash_profile
#
# Notes:
# - $local_username - username you don’t want to see in the prompt - can be defined in ~/.bashlocal : `local_username="admin"`
# - Colors ($RED, $GREEN) - defined in ../tilde/bash_profile.bash
#

# User color
case $(id -u) in
	0) user_color="$RED" ;;  # root
	*) user_color="$GREEN" ;;
esac

# Symbols
prompt_symbol="❯"
prompt_clean_symbol="☀ "
prompt_dirty_symbol="☂ "
prompt_venv_symbol="☁ "

function ahead_behind() {
	curr_branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "");
	if [ "" == "$curr_branch" ]; then
		# Bad HEAD, probably a new repository
		return;
	fi
	curr_remote=$(git config branch.$curr_branch.remote);
	if [ "" ==  "$curr_remote" ]; then
		# No remote
		return;
	fi
	curr_merge_branch=$(git config branch.$curr_branch.merge | cut -d / -f 3-);

	ahead_behind=$(git rev-list --left-right --count $curr_branch...$curr_remote/$curr_merge_branch);
	if [ "" == "$ahead_behind" ] || [ "0\t0" == "$ahead_behind" ]; then
		return;
	fi;

	echo -n " "
	echo "[$GREEN$ahead_behind$NOCOLOR]" | sed "s/\s/$NOCOLOR $RED/"
}

function prompt_command() {
	# Local or SSH session?
	local remote=
	[ -n "$SSH_CLIENT" ] || [ -n "$SSH_TTY" ] && remote=1

	# Git branch name and work tree status (only when we are inside Git working tree)
	local git_prompt=
	if [[ "true" = "$(git rev-parse --is-inside-work-tree 2>/dev/null)" ]]; then
		# Branch name
		local branch="$(git symbolic-ref HEAD 2>/dev/null)"
		branch="${branch##refs/heads/}"

		# Working tree status (red when dirty)
		local dirty=
		# Modified files
		git diff --no-ext-diff --quiet --exit-code --ignore-submodules 2>/dev/null || dirty=1
		# Untracked files
		[ -z "$dirty" ] && test -n "$(git status --porcelain)" && dirty=1

		# Format Git info
		if [ -n "$dirty" ]; then
			git_prompt=" $RED$prompt_dirty_symbol$branch$NOCOLOR"
		else
			git_prompt=" $GREEN$prompt_clean_symbol$branch$NOCOLOR"
		fi

		git_prompt="$git_prompt$(ahead_behind)"
	fi

	# Virtualenv
	local venv_prompt=
	if [ -n "$VIRTUAL_ENV" ]; then
	    venv_prompt=" $BLUE$prompt_venv_symbol$(basename $VIRTUAL_ENV)$NOCOLOR"
	fi

	# Only show username if not default
	local user_prompt=
	[ "$USER" != "$local_username" ] && user_prompt="$user_color$USER$NOCOLOR"

	# Show hostname inside SSH session
	local host_prompt=
	[ -n "$remote" ] && host_prompt="@$YELLOW$HOSTNAME$NOCOLOR"

	# Show delimiter if user or host visible
	local login_delimiter=
	[ -n "$user_prompt" ] || [ -n "$host_prompt" ] && login_delimiter=":"

	# Format prompt
	first_line="$user_prompt$host_prompt$login_delimiter$WHITE\w$NOCOLOR$git_prompt$venv_prompt"
	# Text (commands) inside \[...\] does not impact line length calculation which fixes stange bug when looking through the history
	# $? is a status of last command, should be processed every time prompt prints
	second_line="\`if [ \$? = 0 ]; then echo \[\$CYAN\]; else echo \[\$RED\]; fi\`\$prompt_symbol\[\$NOCOLOR\] "
	PS1="\n$first_line\n$second_line"

	# Multiline command
	PS2="\[$CYAN\]$prompt_symbol\[$NOCOLOR\] "

	# Terminal title
	local title="$(basename $PWD)"
	[ -n "$remote" ] && title="$title | $HOSTNAME"
	echo -ne "\033]0;$title"; echo -ne "\007"
}

# Show awesome prompt only if Git is istalled
command -v git >/dev/null 2>&1 && PROMPT_COMMAND=prompt_command

# ~/.bashrc: executed by bash(1) for non-login shells.
# see /usr/share/doc/bash/examples/startup-files (in the package bash-doc)
# for examples

# Source global definitions, distros like to place these little here and
# there...
if [ -f /etc/bashrc ]; then
        . /etc/bashrc
fi
if [ -f /etc/bash.bashrc ]; then
    source /etc/bash.bashrc
fi

# If not running interactively, don't do anything
case $- in
    *i*) ;;
      *) return;;
esac

# don't put duplicate lines or lines starting with space in the history.
# See bash(1) for more options
HISTCONTROL=ignoreboth

# append to the history file, don't overwrite it
shopt -s histappend

# for setting history length see HISTSIZE and HISTFILESIZE in bash(1)
HISTSIZE=1000
HISTFILESIZE=2000

# check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
shopt -s checkwinsize

# disable ^S/^Q (XON/XOFF) flow control
stty -ixon

# If set, the pattern "**" used in a pathname expansion context will
# match all files and zero or more directories and subdirectories.
#shopt -s globstar

# make less more friendly for non-text input files, see lesspipe(1)
[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

# set variable identifying the chroot you work in (used in the prompt below)
if [ -z "${debian_chroot:-}" ] && [ -r /etc/debian_chroot ]; then
    debian_chroot=$(cat /etc/debian_chroot)
fi

# set a fancy prompt (non-color, unless we know we "want" color)
case "$TERM" in
    xterm-color|*-256color) color_prompt=yes;;
esac

# uncomment for a colored prompt, if the terminal has the capability; turned
# off by default to not distract the user: the focus in a terminal window
# should be on the output of commands, not on the prompt
force_color_prompt=yes

if [ -n "$force_color_prompt" ]; then
    if [ -x /usr/bin/tput ] && tput setaf 1 >&/dev/null; then
	# We have color support; assume it's compliant with Ecma-48
	# (ISO/IEC-6429). (Lack of such support is extremely rare, and such
	# a case would tend to support setf rather than setaf.)
	color_prompt=yes
    else
	color_prompt=
    fi
fi

if [ "$color_prompt" = yes ]; then
    PS1='${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
else
    PS1='${debian_chroot:+($debian_chroot)}\u@\h:\w\$ '
fi
unset color_prompt force_color_prompt

# If this is an xterm set the title to user@host:dir
case "$TERM" in
xterm*|rxvt*)
    PS1="\[\e]0;${debian_chroot:+($debian_chroot)}\u@\h: \w\a\]$PS1"
    ;;
*)
    ;;
esac

# enable color support of ls and also add handy aliases
if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    alias ls='ls --color=auto'
    #alias dir='dir --color=auto'
    #alias vdir='vdir --color=auto'

    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
fi

# Alias definitions.
# You may want to put all your additions into a separate file like
# ~/.bash_aliases, instead of adding them here directly.
# See /usr/share/doc/bash-doc/examples in the bash-doc package.

if [ -f ~/.bash_aliases ]; then
    . ~/.bash_aliases
fi


##### Custom Functions (courtesy of https://github.com/elasticdog/dotfiles/blob/master/bash/.bashrc)

# list only directories
function lsd { ls -l --file-type $* | grep /; }

# extract various types of archive files
function extract {
	if [[ -z "$1" ]]; then
		echo 'Usage: extract ARCHIVE'
		echo 'Extract files from ARCHIVE to the current directory'
	elif [[ -r "$1" ]]; then
		case $1 in
			*.rar)      unrar x "$1"     ;;
			*.tar)      tar -xvf "$1"    ;;
			*.tar.bz2)  tar -xjvf "$1"   ;;
			*.bz2)      bzip2 -d "$1"    ;;
			*.tar.gz)   tar -xzvf "$1"   ;;
			*.gz)       gunzip -d "$1"   ;;
			*.tgz)      tar -xzvf "$1"   ;;
			*.Z)        uncompress "$1"  ;;
			*.zip)      unzip "$1"       ;;

			*) echo "ERROR: '$1' is not a known archive type"  ;;
		esac
	else
		echo "ERROR: '$1' is not a valid file"
	fi
}

# find file by name in the current directory
function ff {
	if [[ -z $1 ]]; then
		echo 'Usage: ff PATTERN'
		echo 'Recursively search for a file named PATTERN in the current directory'
	else
		find . -type f -iname "$1"
	fi
}

# find directory by name in the current directory
function fd {
	if [[ -z $1 ]]; then
		echo 'Usage: fd PATTERN'
		echo 'Recursively search for a directory named PATTERN in the current directory'
	else
		find . -type d -iname "$1"
	fi
}

# Print out environment variables of a process
function envps { tr '\0' '\n' < "/proc/${1}/environ" | sort; }

# enable programmable completion features (you don't need to enable
# this, if it's already enabled in /etc/bash.bashrc and /etc/profile
# sources /etc/bash.bashrc).
if ! shopt -oq posix; then
  if [ -f /usr/share/bash-completion/bash_completion ]; then
    . /usr/share/bash-completion/bash_completion
  elif [ -f /etc/bash_completion ]; then
    . /etc/bash_completion
  fi
fi

# Install krew
if [ -z "$KREW_ROOT" ]; then
	export PATH=${KREW_ROOT}:$PATH
elif [ -d "$HOME/.krew" ]; then
	export PATH=${HOME}/.krew/bin:$PATH
fi

# User specific aliases and functions. We don't use this for the time being, but
# it's a good idea coming from fedora.
if [ -d ~/.bashrc.d ]; then
	for rc in ~/.bashrc.d/*; do
		if [ -f "$rc" ]; then
			. "$rc"
		fi
	done
fi

# Source ble.sh if installed and running interactively
XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
source "${XDG_DATA_HOME}/blesh/ble.sh"

# Source liquidprompt if installed and running interactively
if [[ $- = *i* ]] && [[ -f "${HOME}/.local/bin/starship" ]]; then
	eval "$("$HOME/.local/bin/starship" init bash)"
fi
unset rc

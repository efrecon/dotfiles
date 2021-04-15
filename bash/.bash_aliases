# some more ls aliases
alias l='ls -CF'        # Columned list with types.
alias la='ls -A'        # list all files/directories
alias lla='ls -lhA'     # list details of all files/directories
alias ll='ls -lh'       # list details of visible files/directories
alias lh='ls -d .*'     # list hidden files/directories
alias llh='ls -lhd .*'  # list details of hidden files/directories

# Add an "alert" alias for long running commands.  Use like so:
#   sleep 10; alert
alias alert='notify-send --urgency=low -i "$([ $? = 0 ] && echo terminal || echo error)" "$(history|tail -n1|sed -e '\''s/^\s*[0-9]\+\s*//;s/[;&|]\s*alert$//'\'')"'

#!/usr/bin/env sh

AENV=${HOME}/.ssh/agent.env


agent_load_env () {
    [ -f "$AENV" ] && . "$AENV" > /dev/null
}

agent_start () {
    ( umask 077; [ -f "$AENV" ] && rm -f "$AENV"; ssh-agent > "$AENV" )
    . "$AENV" > /dev/null
}

agent_load_env

# agent_run_state: 0=agent running w/ key; 1=agent w/o key; 2= agent not running
agent_run_state=$(ssh-add -l > /dev/null 2>&1; echo $?)

if [ ! "$SSH_AUTH_SOCK" ] || [ $agent_run_state = 2 ]; then
    agent_start
    ssh-add
elif [ "$SSH_AUTH_SOCK" ] && [ $agent_run_state = 1 ]; then
    ssh-add
fi

unset AENV
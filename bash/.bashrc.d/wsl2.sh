#!/usr/bin/env sh

if uname -r | grep -q WSL2; then
    # Start docker daemon if not already running. This is needed on older
    # versions of WSL2 that did not support systemd.
    if command -v service > /dev/null; then
        service docker status > /dev/null || sudo service docker start
    fi

    # Copy Windows SSH keys into Linux VM
    if [ -f "${HOME}/bin/wsl2/ssh-copy.sh" ]; then
        . "${HOME}/bin/wsl2/ssh-copy.sh"
    fi

    # Start SSH agent
    if [ -f "${HOME}/bin/wsl2/ssh-agent.sh" ]; then
        . "${HOME}/bin/wsl2/ssh-agent.sh"
    fi

    # Copy Windows SSH keys into Linux VM
    if [ -f "${HOME}/bin/wsl2/git-copy.sh" ]; then
        . "${HOME}/bin/wsl2/git-copy.sh"
    fi
fi

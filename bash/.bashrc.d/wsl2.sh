#!/usr/bin/env sh

echo "Running wsl2 tweaks"
if uname -r | grep -q WSL2; then
    # Start docker daemon if not already running.
    service docker status > /dev/null || sudo service docker start

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

#!/usr/bin/env sh

BINENV_ROOTDIR=$( cd -P -- "$(dirname -- "$(command -v -- "$0")")" && pwd -P )
INSTALL_ROOTDIR=$(dirname "$BINENV_ROOTDIR")
INSTALL_LIBPATH=${INSTALL_LIBPATH:-${INSTALL_ROOTDIR}/lib}

BINENV_VERSION=0.21.1
BINENV_BINARIES="act age age-keygen \
                    bat bottom broot btop \
                    ctop \
                    delta dive dust \
                    exa \
                    fx \
                    geesefs gh glab glow gotty gping gron \
                    lazydocker lazygit lsd \
                    procs \
                    rga \
                    sysz \
                    yh yj"

# Look for modules passed as parameters in the INSTALL_LIBPATH and source them.
# Modules are required so fail as soon as it was not possible to load a module
module() {
  for module in "$@"; do
    OIFS=$IFS
    IFS=:
    for d in $INSTALL_LIBPATH; do
      if [ -f "${d}/${module}.sh" ]; then
        # shellcheck disable=SC1090
        . "${d}/${module}.sh"
        IFS=$OIFS
        break
      fi
    done
    if [ "$IFS" = ":" ]; then
      echo "Cannot find module $module in $INSTALL_LIBPATH !" >& 2
      exit 1
    fi
  done
}

module log controls utils

if [ -x "${HOME}/.binenv/binenv" ]; then
    BINENV_BOOTSTRAP="${HOME}/.binenv/binenv"
else
    log_info "Bootstraping with binenv ${BINENV_VERSION}"
    download "https://github.com/devops-works/binenv/releases/download/v${BINENV_VERSION}/binenv_linux_amd64" /tmp/binenv
    chmod a+x /tmp/binenv
    BINENV_BOOTSTRAP="/tmp/binenv"
fi

log_info "Updating and installing latest binenv using binary at $BINENV_BOOTSTRAP"
"$BINENV_BOOTSTRAP" update
"$BINENV_BOOTSTRAP" install binenv

for tool in $BINENV_BINARIES; do
    log_info "Installing $tool"
    "$BINENV_BOOTSTRAP" install "$tool"
done

if [ -f /tmp/binenv ]; then
    rm -f /tmp/binenv
fi

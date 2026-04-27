#!/usr/bin/env sh

DISTILLERY_ROOTDIR=$( cd -P -- "$(dirname -- "$(command -v -- "$0")")" && pwd -P )
INSTALL_ROOTDIR=$(dirname "$DISTILLERY_ROOTDIR")
INSTALL_LIBPATH=${INSTALL_LIBPATH:-${INSTALL_ROOTDIR}/lib}

DISTILLERY_INSTALL_URL="https://get.dist.sh"

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


log_info "Installing distillery from $DISTILLERY_INSTALL_URL"
download "$DISTILLERY_INSTALL_URL" | sh

log_info "Installation complete, running distillery with $HOME/.distillery/tools.distfile"
"$HOME/.distillery/bin/distillery" run "$HOME/.distillery/tools.distfile"

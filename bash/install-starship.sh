#!/usr/bin/env sh

BASH_ROOTDIR=$( cd -P -- "$(dirname -- "$(command -v -- "$0")")" && pwd -P )
INSTALL_ROOTDIR=$(dirname "$BASH_ROOTDIR")
INSTALL_LIBPATH=${INSTALL_LIBPATH:-${INSTALL_ROOTDIR}/lib}

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


# Make XDG bin directory
if ! [ -d "${HOME}/.local/bin" ]; then
  mkdir -p "${HOME}/.local/bin"
fi
if [ -x "${HOME}/.local/bin/starship" ]; then
  log_info "starship is already installed."
else
  download https://starship.rs/install.sh - | sh -s - -f -b "${HOME}/.local/bin"
fi

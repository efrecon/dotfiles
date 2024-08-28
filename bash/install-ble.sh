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

XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"

if [ -d "${XDG_DATA_HOME}/blesh" ]; then
  log_info "ble is already installed."
else
  tmp=$(mktemp -d)
  download https://github.com/akinomyoga/ble.sh/releases/download/nightly/ble-nightly.tar.xz - | tar -C "$tmp" -xJf -
  mkdir -p "${XDG_DATA_HOME}/blesh"
  cp -Rf "${tmp}"/ble-nightly/* "${XDG_DATA_HOME}/blesh/"
  rm -rf "$tmp"
fi

#!/usr/bin/env sh

EXT_ROOTDIR=$( cd -P -- "$(dirname -- "$(command -v -- "$0")")" && pwd -P )
INSTALL_ROOTDIR=$(dirname "$EXT_ROOTDIR")
INSTALL_LIBPATH=${INSTALL_LIBPATH:-${INSTALL_ROOTDIR}/lib}
XDG_DATA_HOME=${XDG_DATA_HOME:-${HOME}/.local/share}
INSTALL_TARGET=${INSTALL_TARGET:-${XDG_DATA_HOME}/gnome-shell/extensions}

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
if [ -f "${INSTALL_TARGET}/.local/share/gnome-shell/extensions/.unforge" ]; then
      log_info "Extracting extensions indexed at ${INSTALL_TARGET}/.local/share/gnome-shell/extensions/.unforge"
      (
            cd "${INSTALL_TARGET}/.local/share/gnome-shell/extensions"
            $INSTALL_ROOTDIR/libexec/unforge/unforge.sh -vv -f install -p off
      )
else
      log_warn "No unforge extension index found at ${INSTALL_TARGET}/.local/share/gnome-shell/extensions/.unforge"
fi

# Recompile schemas on the local machine, see: https://askubuntu.com/questions/1178580/where-are-gnome-extensions-preferences-stored
log_info "Recompiling schemas"
find  "${INSTALL_TARGET}/.local/share/gnome-shell/extensions" \
      -mindepth 1 -maxdepth 1 -type d \
      -exec glib-compile-schemas "{}/schemas" \; 2>/dev/null

# Push back the settings from the repo file. This file has to be regenerated
# everytime some settings, in some extension, change.
log_info "Enforcing settings"
dconf load /org/gnome/shell/extensions/ < "${EXT_ROOTDIR}/extensions.dconf"

# Extensions that have been copied into their official locations are disabled by
# default, this will enable them...
log_info "Enabling disabled user extensions"
gnome-extensions list --disabled --user |
      xargs -r -I '{}' gnome-extensions enable \{\}

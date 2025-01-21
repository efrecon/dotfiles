#!/usr/bin/env sh

EXT_ROOTDIR=$( cd -P -- "$(dirname -- "$(command -v -- "$0")")" && pwd -P )
INSTALL_ROOTDIR=$(dirname "$EXT_ROOTDIR")
INSTALL_LIBPATH=${INSTALL_LIBPATH:-${INSTALL_ROOTDIR}/lib}
XDG_DATA_HOME=${XDG_DATA_HOME:-${INSTALL_TARGET}/.local/share}
GNOME_EXTENSIONS_DIR=${GNOME_EXTENSIONS_DIR:-${XDG_DATA_HOME}/gnome-shell/extensions}

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


for uuid in \
  "iso-clock@tweekism.fairchild.au" \
  "caffeine@patapon.info" \
  "freon@UshakovVasilii_Github.yahoo.com" \
  "display-brightness-ddcutil@themightydeity.github.com" \
  "status-area-horizontal-spacing@mathematical.coffee.gmail.com" \
  "BingWallpaper@ineffable-gmail.com" \
  "clipboard-indicator@tudmotu.com" \
  "tilingshell@ferrarodomenico.com" ; do
  if ! gnome-extensions list | grep -Fq "$uuid"; then
    log_info "Installing extension ${uuid}"
    # Note: this will pop up a dialog asking for confirmation
    gdbus call \
      --session \
      --dest org.gnome.Shell.Extensions \
      --object-path /org/gnome/Shell/Extensions \
      --method org.gnome.Shell.Extensions.InstallRemoteExtension "$uuid"
  else
    log_info "Extension ${uuid} already installed"
  fi
done

log_info "For ddc-brightness-contrast-extra-dimming@tzawezin.github.io or display-brightness-ddcutil@themightydeity.github.com: see requirements here: https://github.com/tzawezin/gnome-ddc-brightness-contrast-extra-dimming"

# Push back the settings from the repo file. This file has to be regenerated
# everytime some settings, in some extension, change.
log_info "Enforcing settings"
dconf load /org/gnome/shell/extensions/ < "${EXT_ROOTDIR}/extensions.dconf"

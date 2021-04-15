#!/usr/bin/env sh

EXT_ROOTDIR=$( cd -P -- "$(dirname -- "$(command -v -- "$0")")" && pwd -P )

# Recompile schemas on the local machine, see: https://askubuntu.com/questions/1178580/where-are-gnome-extensions-preferences-stored
find  "${HOME}/.local/share/gnome-shell/extensions" \
      -mindepth 1 -maxdepth 1 -type d \
      -exec glib-compile-schemas "{}/schemas" \; 2>/dev/null

# Push back the settings from the repo file. This file has to be regenerated
# everytime some settings, in some extension, change.
dconf load /org/gnome/shell/extensions/ < "${EXT_ROOTDIR}/extensions.dconf"
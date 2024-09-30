#!/bin/sh

FONTS_ROOTDIR=$( cd -P -- "$(dirname -- "$(command -v -- "$0")")" && pwd -P )
INSTALL_ROOTDIR=$(dirname "$FONTS_ROOTDIR")
XDG_DATA_HOME=${XDG_DATA_HOME:-${INSTALL_TARGET}/.local/share}

mkdir -p "${XDG_DATA_HOME}/fonts"
"${INSTALL_ROOTDIR}/libexec/hack-linux-installer/hack-linux-installer.sh" v3.003
#!/usr/bin/env sh

XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"

if [ -d "${XDG_DATA_HOME}/blesh" ]; then
  echo "ble is already installed."
else
  tmp=$(mktemp -d)
  wget -O - https://github.com/akinomyoga/ble.sh/releases/download/nightly/ble-nightly.tar.xz | tar -C "$tmp" -xJf -
  mkdir -p "${XDG_DATA_HOME}/blesh"
  cp -Rf "${tmp}"/ble-nightly/* "${XDG_DATA_HOME}/blesh/"
  rm -rf "$tmp"
fi

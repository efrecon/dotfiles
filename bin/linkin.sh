#!/usr/bin/env sh

DOTFILES_ROOTDIR=$(dirname "$( cd -P -- "$(dirname -- "$(command -v -- "$0")")" && pwd -P )")

ln -sf "$DOTFILES_ROOTDIR/libexec/dew/dew.sh" "$HOME/bin/dew"
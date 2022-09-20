#!/usr/bin/env sh

BASH_ROOTDIR=$( cd -P -- "$(dirname -- "$(command -v -- "$0")")" && pwd -P )
DOTFILES_ROOTDIR=$(dirname "$BASH_ROOTDIR")

if [ -f "${DOTFILES_ROOTDIR}/libexec/liquidprompt/liquidprompt" ]; then
  # Make XDG bin directory
  if ! [ -d "${HOME}/.local/bin" ]; then
    mkdir -p "${HOME}/.local/bin"
  fi
  # Link path to this liquidprompt into the XDG bin directory to make it
  # accessible.
  ln -sf \
    "${DOTFILES_ROOTDIR}/libexec/liquidprompt/liquidprompt" \
    "${HOME}/.local/bin/liquidprompt"
fi

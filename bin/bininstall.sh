#!/usr/bin/env sh

BININSTALL_ROOTDIR=$( cd -P -- "$(dirname -- "$(command -v -- "$0")")" && pwd -P )
INSTALL_ROOTDIR=$(dirname "$BININSTALL_ROOTDIR")
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

install_systemctl_tui() {
  if ! [ -f "${HOME}/.local/bin/systemctl-tui" ]; then
    proj=rgwood/systemctl-tui
    latest=$("${INSTALL_ROOTDIR}/libexec/reg-tags/bin/github_releases.sh" "$proj"|head -n 1)
    if [ -n "$latest" ]; then
      log_info "Installing systemctl-tui ${latest}..."
      # Make XDG bin directory
      "${INSTALL_ROOTDIR}/libexec/bininstall/tarinstall.sh" \
          -v \
          -x systemctl-tui \
          -d "${HOME}/.local/bin" \
          "https://github.com/${proj}/releases/download/${latest}/systemctl-tui-$(uname -m)-unknown-linux-musl.tar.gz"
    fi
  else
    log_info "systemctl-tui is already installed as ${HOME}/.local/bin/systemctl-tui"
  fi
}

install_micro() {
  if ! [ -f "${HOME}/.local/bin/micro" ]; then
    proj=zyedidia/micro
    latest=$("${INSTALL_ROOTDIR}/libexec/reg-tags/bin/github_releases.sh" "$proj"|head -n 1)
    if [ -n "$latest" ]; then
      log_info "Installing micro ${latest}..."
      # Make XDG bin directory
      "${INSTALL_ROOTDIR}/libexec/bininstall/tarinstall.sh" \
          -v \
          -x "micro-${latest#v}/micro" \
          -d "${HOME}/.local/bin" \
          "https://github.com/${proj}/releases/download/${latest}/micro-${latest#v}-linux64-static.tar.gz"
    fi
  else
    log_info "micro is already installed as ${HOME}/.local/bin/micro"
  fi
}

if [ -x "${INSTALL_ROOTDIR}/libexec/bininstall/tarinstall.sh" ] \
  && [ -x "${INSTALL_ROOTDIR}/libexec/reg-tags/bin/github_releases.sh" ]; then
  if ! [ -d "${HOME}/.local/bin" ]; then
    mkdir -p "${HOME}/.local/bin"
  fi

  install_systemctl_tui
  install_micro
fi

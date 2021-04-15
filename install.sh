#!/usr/bin/env sh

# If editing from Windows. Choose LF as line-ending

set -eu

# Find out where dependent modules are and load them at once before doing
# anything. This is to be able to use their services as soon as possible.

# Build a default colon separated INSTALL_LIBPATH using the root directory to
# look for modules that we depend on. INSTALL_LIBPATH can be set from the outside
# to facilitate location.
INSTALL_ROOTDIR=$( cd -P -- "$(dirname -- "$(command -v -- "$0")")" && pwd -P )
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

# Source in all relevant modules. This is where most of the "stuff" will occur.
module log controls

# Target Diretory
INSTALL_TARGET=${INSTALL_TARGET:-"$HOME"}

# Do nothing, just print out what would be done
INSTALL_DRYRUN=${INSTALL_DRYRUN:-0}

# Backup directory root.
INSTALL_BACKUP=${INSTALL_BACKUP:-"${HOME%/}/.backup"}

# Date format string to generate the backup directory names under the root
INSTALL_BACKFMT=${INSTALL_BACKFMT:-"%Y%m%d-%H%M%S"}

# Glob-style pattern of files and directories that will be considered for
# copying to the target directory, from the tools directories.
INSTALL_DOTFILES=${INSTALL_DOTFILES:-".*"}

# Glob-style pattern of executables that will be considered for running from the
# within the tools directories when installing.
INSTALL_EXEFILES=${INSTALL_EXEFILES:-"*.sh"}

# shellcheck disable=2034 # Usage string is used by log module on errors
EFSL_USAGE="
Synopsis:
  Install dotfiles into home directory

Usage:
  $EFSL_CMDNAME [-option arg] [--] [tool]...
  where all dash-led single options are as follows:
    -t | --target    Target directory, default to \$HOME
    -v | --verbosity One of: error, warn, notice, info, debug or trace
  
  All arguments (possibly after the double-dash separator) will be
  patterns passed to find and matching known tools to install. The
  behaviour is to install ALL known tools when no argument is passed!
"

# Parse options
while [ $# -gt 0 ]; do
  case "$1" in
    -t | --target)
      INSTALL_TARGET=$2; shift 2;;
    --target=*)
      INSTALL_TARGET="${1#*=}"; shift 1;;

    --dry-run | --dryrun)
      INSTALL_DRYRUN=1; shift 1;;

    -v | --verbosity | --verbose)
      EFSL_VERBOSITY=$2; shift 2;;
    --verbosity=* | --verbose=*)
      # shellcheck disable=2034 # Comes from log module
      EFSL_VERBOSITY="${1#*=}"; shift 1;;

    -\? | -h | --help)
      usage 0;;
    --)
      shift; break;;
    -*)
      usage 1 "Unknown option: $1 !";;
    *)
      break;
  esac
done

# Return the name of the distribution that this script is running on. The name
# will always be in lower-case. We consider mingw, cygwin and the like as
# distributions. WSL2 is pure linux, so it will pass the linux test.
distro() {
  if [ "$(uname)" = "Darwin" ]; then
    printf darwin\\n
  elif [ "$(expr substr $(uname -s) 1 10)" = "MINGW32_NT" ] \
        || [ "$(expr substr $(uname -s) 1 10)" = "MINGW64_NT" ]; then
    printf mingw\\n
  elif [ "$(expr substr $(uname -s) 1 5)" = "Linux" ]; then
    if [ -r /etc/os-release ]; then
      # shellcheck disable=SC1091
      (. /etc/os-release && echo "$ID" | tr '[:upper:]' '[:lower:]')
    else
      printf linux\\n
    fi
  fi
}

# Prints out the list of tools in the distribution-specific directory (all or
# the one matching the patter passed as a parameter). Hopefully, this list
# should be empty to allow for the same environment on all destination machines.
distro_tools() {
  if [ -d "${INSTALL_ROOTDIR}/distro/$(distro)" ]; then
    find "${INSTALL_ROOTDIR}/distro/$(distro)" -mindepth 1 -maxdepth 1 -type d -name "${1:-*}"
  fi
}

# Prints out the list of generic tools, apart for those that require
# distribution-specific tweaks, matching the pattern passed as a parameter (or
# all)
tools() {
  # Note that the grep jumps over: the distro directory because this is where we
  # store distribution specific sub-directories for tools, the lib directory
  # because this is where we store some of our code (libraries), and any
  # directory that would start with a dot . (to avoid the git directory itself
  # for this repo itself).
  find "${INSTALL_ROOTDIR}" -mindepth 1 -maxdepth 1 -type d -name "${1:-*}" |
    grep -vE '/(lib|distro|\..*)$'
}

# Install the tool which path is passed as an argument to the target directory.
# Installation will recursively copy all the content of the source to the
# target.
install_tool() {
  tool=$(basename "$1")

  if [ "$INSTALL_DRYRUN" = "0" ]; then
    # Backup existing version of the dotfiles and directories having the same
    # name as the ones under the directory at $1 into the backup directory for
    # this run (this directory will have a unique name across time (and runs))
    if [ -n "$INSTALL_BACKDIR" ]; then
      log_info "Backing up existing versions of $tool to $INSTALL_BACKDIR"
      find "$1" -mindepth 1 -maxdepth 1 -name "$INSTALL_DOTFILES" |
        xargs -r -I '{}' basename \{\} |
        xargs -r -I '{}' cp -a "${INSTALL_TARGET%/}/{}" "$INSTALL_BACKDIR"
    fi
    # Now Recursively copy all the files that are under the tool's directory
    # into the target directory.
    log_notice "Installing $tool from $1 to $INSTALL_TARGET"
    find "$1" -mindepth 1 -maxdepth 1 -name "$INSTALL_DOTFILES" \
              -exec cp -a "{}" "$INSTALL_TARGET" \;
    # And then time for the most dangerous operation: execute any installation
    # helper that would be present in the directory.
    exe=$(find "$1" -mindepth 1 -maxdepth 1 -executable -type f -name "$INSTALL_EXEFILES")
    if [ -n "$exe" ]; then
      log_info "Running installation helpers for $tool from $1"
      find "$1" -mindepth 1 -maxdepth 1 -executable -type f -name "$INSTALL_EXEFILES" \
                -exec \{\} \;
    fi
  else
    # Just printout what would be done. This code is similar to the one above,
    # apart from the additional "echo". It should be kept in sync, in order to
    # easily verify any changes that would be made to this logic. When running
    # with the trace option, this will, in addition print out the exact copy
    # commands that would be issued.
    if [ -n "$INSTALL_BACKDIR" ]; then
      log_info "Would backup existing versions of $tool to $INSTALL_BACKDIR"
      if at_verbosity trace; then
        find "$1" -mindepth 1 -maxdepth 1 -name "$INSTALL_DOTFILES" |
          xargs -r -I '{}' basename \{\} |
          xargs -r -I '{}' echo cp -a "${INSTALL_TARGET%/}/{}" "$INSTALL_BACKDIR" >&2
      fi
    fi
    log_info "Would install $tool from $1 to $INSTALL_TARGET"
    if at_verbosity trace; then
      find "$1" -mindepth 1 -maxdepth 1 -name "$INSTALL_DOTFILES" \
                -exec echo cp -a "{}" "$INSTALL_TARGET" >&2 \;
    fi
    exe=$(find "$1" -mindepth 1 -maxdepth 1 -executable -type f -name "$INSTALL_EXEFILES")
    if [ -n "$exe" ]; then
      log_info "Would execute installation helpers for $tool from $1"
      if at_verbosity trace; then
        find "$1" -mindepth 1 -maxdepth 1 -executable -type f -name "$INSTALL_EXEFILES" \
                  -exec echo \{\} >&2 \;
      fi
    fi
  fi
}

# Install all tools which path is got from the standard input if they haven't
# already been installed. The list of installed tools is kept in the global
# INSTALLED and will contain the name of each installed tools, one per line.
install() {
  while IFS= read -r tool_path; do
    if printf %s\\n "$INSTALLED" | grep -vq $(basename "$tool_path") && install_tool "$tool_path"; then
      INSTALLED="${INSTALLED}\n$(basename $tool_path)"
    fi
  done  
}

# Compute the location of backups for this run
INSTALL_BACKDIR=
if [ -n "$INSTALL_BACKUP" ]; then
  INSTALL_BACKDIR=${INSTALL_BACKUP%/}/$(date +"$INSTALL_BACKFMT")
  if [ "$INSTALL_DRYRUN" = "0" ] && ! mkdir -p "$INSTALL_BACKDIR"; then
    die "Could not create backup directory at $INSTALL_BACKDIR"
  fi
fi

# This global will contain the list of installed tools, one per line.
INSTALLED=

# Install the distribution specific tools. If these have been installed, they
# won't be installed from the set of generic tools. This allows to override the
# installation of some tool for specific platforms.
if [ "$#" = "0" ]; then
  if [ -n "$(distro_tools)" ]; then
    install<<EOF
$(distro_tools)
EOF
  fi
else
  for ptn in "$@"; do
    if [ -n "$(distro_tools "$ptn")" ]; then
      install<<EOF
$(distro_tools "$ptn")
EOF
    fi
  done
fi

# Now install all tools that wouldn't have been installed from their
# distribution specific directory into the target dir.
if [ "$#" = "0" ]; then
  if [ -n "$(tools)" ]; then
    install<<EOF
$(tools)
EOF
  fi
else
  for ptn in "$@"; do
    if [ -n "$(tools "$ptn")" ]; then
      install<<EOF
$(tools "$ptn")
EOF
    fi
  done
fi

# Print out the list of tools that were installed
printf "$INSTALLED"|tr '\n' " "|cut -c 2-
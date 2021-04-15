#!/usr/bin/env sh

# This is a cleaned up version of https://stackoverflow.com/a/18600920. It
# properly passes shellcheck's default set of rules.
let() {
  dynvar_name=$1;
  #shellcheck disable=SC2034
  dynvar_value=${2:-""};

  # Allow variables to be unset.
  _oldstate=$(set +o); set +u

  dynvar_count_var=${dynvar_name}_dynvar_count
  if [ "$(eval echo "$dynvar_count_var")" ]; then
    eval "$dynvar_count_var"='$(( $'"$dynvar_count_var"' + 1 ))'
  else
    eval "$dynvar_count_var"=0
  fi

  eval dynvar_oldval_var="${dynvar_name}"_oldval_'$'"$dynvar_count_var"
  #shellcheck disable=SC2154
  eval "$dynvar_oldval_var"='$'"$dynvar_name"

  eval "$dynvar_name"='$'dynvar_value

  # Restore set state
  set +vx; eval "$_oldstate"  
}

unlet() {
  for dynvar_name; do
    dynvar_count_var=${dynvar_name}_dynvar_count
    eval dynvar_oldval_var="${dynvar_name}"_oldval_'$'"$dynvar_count_var"
    eval "$dynvar_name"='$'"$dynvar_oldval_var"
    eval unset "$dynvar_oldval_var"
    eval "$dynvar_count_var"='$(( $'"$dynvar_count_var"' - 1 ))'
  done
}

backoff_loop() {
  # Default when nothing is specified is to loop forever every second.

  # All variables are declared local so that recursive calls are possible.
  # shellcheck disable=SC2039
  let _wait 1
  # shellcheck disable=SC2039
  let _max
  # shellcheck disable=SC2039
  let _mult
  # shellcheck disable=SC2039
  let _timeout

  # Parse arguments
  while [ $# -gt 0 ]; do
    case "$1" in
        -l | --loop)
          _wait=$(printf %s\\n "$2" | awk -F: '{print $1}')
          _max=$(printf %s\\n "$2" | awk -F: '{print $2}')
          _mult=$(printf %s\\n "$2" | awk -F: '{print $3}')
          _timeout=$(printf %s\\n "$2" | awk -F: '{print $4}')
          shift 2;;
        --loop=*)
          _wait=$(printf %s\\n "${1#*=}" | awk -F: '{print $1}')
          _max=$(printf %s\\n "${1#*=}" | awk -F: '{print $2}')
          _mult=$(printf %s\\n "${1#*=}" | awk -F: '{print $3}')
          _timeout=$(printf %s\\n "${1#*=}" | awk -F: '{print $4}')
          shift;;
        -s | --sleep)
          _wait=$2; shift 2;;
        --sleep=*)
          _wait=${1#*=}; shift;;
        -m | --max | --maximum)
          _max=$2; shift 2;;
        --max=* | --maximum=*)
          _max=${1#*=}; shift;;
        -f | --factor | --multiplier)
          _mult=$2; shift 2;;
        --factor=* | --multiplier=*)
          _mult=${1#*=}; shift;;
        -t | --timeout)
          _timeout=$2; shift 2;;
        --timeout=*)
          _timeout=${1#*=}; shift;;
        --)
          shift; break;;
        -*)
          log_warn "$1 Unknown option!"
          return 1;;
        *)
          break;;
    esac
  done

  # Check arguments for sanity
  if [ -n "$_wait" ] && ! printf %s\\n "$_wait" | grep -q '[0-9]'; then
    log_warn "(Initial) waiting time $_wait not an integer!"; return 1
  fi
  if [ -n "$_max" ] && ! printf %s\\n "$_max" | grep -q '[0-9]'; then
    log_warn "Maximum waiting time $_max not an integer!"; return 1
  fi
  if [ -n "$_mult" ] && ! printf %s\\n "$_mult" | grep -q '[0-9]'; then
    log_warn "Multiplication factor $_mult not an integer!"; return 1
  fi
  if [ -n "$_timeout" ] && ! printf %s\\n "$_timeout" | grep -q '[0-9]'; then
    log_warn "Timeout $_timeout not an integer!"; return 1
  fi

  # Good defaults
  [ -z "$_mult" ] && _mult=2;   # Default multiplier is 2

  # shellcheck disable=SC2039
  let _waited 0
  while true; do
    # Execute the command and if it returns true, we are done and will exit
    # after cleanup.
    if "$@"; then
      break
    fi

    # Sleep for the initial period
    sleep "$_wait"

    # Timeout reached. We return
    _waited=$(( _waited + _wait))
    if [ -n "$_timeout" ] && [ "$_waited" -ge "$_timeout" ]; then
      break;
    fi

    # If there is no max value we default to waiting the same amount of seconds
    # each time. Otherwise, we use the colon-separated fields to perform
    # exponential backoff and try connecting as soon as possible without too
    # much burden on the DB server.
    if [ -n "$_max" ]; then
      _wait=$(( _wait * _mult ))
      if [ "$_wait" -gt "$_max" ]; then
        _wait=$_max
      fi
    fi
  done

  # Cleanup and exit
  unlet _wait _max _mult _timeout _waited
}
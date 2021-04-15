# E.F. Shell Library

This directory contains a number of scripts snippets that can be directly
sourced in target scripts and provide reusable code. These snippets mainly
target POSIX shell scripts, but using them from other shells such as `bash`
should be fine.

To use these scripts, the following snippet can be copied (and adapted) into
your main script. You should insert this as early on as possible, e.g. typically
right after the shebang and initial documenting comment. The example loads two
scripts from this library, i.e. [`log`](#logging-library) and
[`controls`](#controls-library).

```shell
# Build a default colon separated YOURSCRIPT_LIBPATH using the root directory to
# look for modules that we depend on. YOURSCRIPT_LIBPATH can be set from the outside
# to facilitate location.
YOURSCRIPT_ROOTDIR=$( cd -P -- "$(dirname -- "$(command -v -- "$0")")" && pwd -P )
YOURSCRIPT_LIBPATH=${YOURSCRIPT_LIBPATH:-${YOURSCRIPT_ROOTDIR}/../../../dotfiles/lib:${YOURSCRIPT_ROOTDIR}/lib}

# Look for modules passed as parameters in the YOURSCRIPT_LIBPATH and source them.
# Modules are required so fail as soon as it was not possible to load a module
module() {
  for module in "$@"; do
    OIFS=$IFS
    IFS=:
    for d in $YOURSCRIPT_LIBPATH; do
      if [ -f "${d}/${module}.sh" ]; then
        # shellcheck disable=SC1090
        . "${d}/${module}.sh"
        IFS=$OIFS
        break
      fi
    done
    if [ "$IFS" = ":" ]; then
      echo "Cannot find module $module in $YOURSCRIPT_LIBPATH !" >& 2
      exit 1
    fi
  done
}

# Source in all relevant modules.
module log controls
```

## Logging Library

The [`log`](./log.sh) library provides facilities for logging and exiting out of
script with usage description or as an emergency measure.

### Logging

The logging library implements and recognises the following verbosity levels
(from higher to lower priority): `error`, `warn`, `notice`, `info` (the
default), `debug` and `trace`. Logging will automatically be coloured at the
terminal (but kept black and white in logs) and happens on the `stderr`. The
logging behaviour is controlled by two environment variables:

+ `EFSL_INTERACTIVE` should be `1` or `0` and controls colouring. When running
  in interactive mode, which is automatically detected, log output will be
  coloured.
+ `EFSL_VERBOSITY` is the verbosity level of your application, as described
  above (levels are case insensitive). You would typically set this through a
  command-line option called `-v` or `--verbose` from your main script.

To use the library, call one of the `log_error`, `log_warn`, etc. logging
functions. They all recognise at least one parameter which is the message to
output. The message will be output to `stderr` only if the value of
`EFSL_VERBOSITY` currently matches. These functions also take a second
(optional) argument. This argument is a freeform name that will replace the name
of the application in the log lines. It can be used to segregate between logs
from the main program and logs from modules, for example.

The functions are optimised, they output according to the following template.
This template is designed to give as much information as possible while
facilitating reading. For example it arranges for perfect alignment of the log
message by default.

```
[<name>] [<level>] [<timestamp>] <message>
```

where:

+ `<name>` will be replaced with the name of your script in most cases, sans the
  extension or directory. This name is automatically detected and exported as
  the [variable](#exported-variables) `EFSL_APPNAME`. When colouring is on, this
  is dark gray to let the eyes focus on the rest of the message. The `<name>`
  can also be the name of an internal module, as described above.
+ `<level>` is a 3 letters code representing the level in upper case,
  colour-coded if needed. Keeping it at 3 letters facilitates alignment and
  eases reading.
+ `<timestamp>` will be the timestamp at the second, following the template
  `%Y%m%d-%H%M%S`.
+ `<message>` is the log message itself.

### Colouring

The library implements a number of functions to output in colour whenever the
`EFSL_INTERACTIVE` variable is set to `1` (and without colouring when
`EFSL_INTERACTIVE` is set to `0`). The functions will output the necessary
colouring escape codes around the text passed as an argument. They are called
after their colour names, i.e.

+ `green`
+ `red`
+ `yellow`
+ `blue`
+ `magenta`
+ `cyan`
+ `dark_gray`
+ `light_gray`

### Exported Variables

In addition to `EFSL_INTERACTIVE` and `EFSL_VERBOSITY`, the library exports or
recognises a number of other variables. All these variables start with `EFSL_`.

+ `EFSL_USAGE` can be set from the outside, e.g. from your script. The variable
  will be used by the `usage` function (see below).
+ `EFSL_APPDIR` is set by the library to the root directory of the main script.
+ `EFSL_CMDNAME` is set by the library to the name of the script, i.e. the
  basename.
+ `EFSL_APPNAME` is set by the library to the name of the script without the
  trailing extension.

### Additional Functions

The library also implements a number of utility functions

#### `log`

`log` is simply an alias to `log_info`, `info` being the default logging level.
This function is for the lazy programmer, or when you are really in a hurry...

#### `die`

`die` will print the message passed as an argument at the `error` level and exit
the script at once with an error (the exitcode being set to `1`).

#### `check_verbosity`

`check_verbosity` tests if the verbosity level passed as an argument (or, if
none provided, the value of `EFSL_VERBOSITY`) is a recognised verbosity level. You
could use the function at the beginning of your script with a construction
similar to the following:

```shell
if ! check_verbosity "$EFSL_VERBOSITY"; then
    usage 1 "$EFSL_VERBOSITY is not a recognised verbosity level"
fi
```

#### `usage`

`usage` will print out a usage summary for the script and exit. Usage summary is
taken from the variable `EFSL_USAGE`, a variable that you should have set prior to
calling `usage`. When the variable does not exist, a default message will be
print out.

`usage` takes two optional parameters:

+ The first parameter should be the exit code, by default this is `1` thus
  reporting an error.
+ The second parameter is an optional message that would be output before the
  usage summary. This message can be used to describe further what was wrong.

Both the optional message and the usage string are output to the `stderr`.

## Controls Library

The controls library provides additional programming constructs that are
otherwise missing from the (POSIX) shell implementations.

### Local Variables

In POSIX shell, by default, all variables are local. This means that recursion
is a nightmare and that variables may leak between functions. In other words...
it is a programmer's nightmare. Most implementations will recognise `local`, but
this is not officially part of the POSIX standard (and will fail on
ancient/exotic shells). The controls library provides two functions as a remedy.
The idea is to call [`let`](#let) as many times as needed at the beginning of
your function, and to call [`unlet`](#unlet) prior to quitting the function.

#### `let`

`let` takes one or two arguments. The first (mandatory) argument is the name of
a variable that will be made local to that function. The second argument is the
initial value of the variable; when it is not present, the variable will be
initialised to the empty string.

#### `unlet`

`unlet` takes any number of arguments, all being the names of variables that had
been declared local using [`let`](#let). You ***must*** call `unlet` before
exiting a function if you want to properly benefit from the facilities offered
by this module.

### Exponential Back-Off Looping

The function `backoff_loop` implements exponential back-off calling of its
argument. In other words, it will call the command passed as argument on and on
until it succeeds. The time waited between unsuccessfull calls will increase,
each time and in an exponential way. Note that this feature can be turned off,
letting the `backoff_loop` function that will loop at fixed intervals until the
command passed as argument is a success. `backoff_loop` takes a number of
command-line options before the command that it will loop as an argument. You
can make the separation between the options and the argument explicit by
inserting a `--`. Options are either single-dash led one-letter options, or
double-dashed led long options. Long options can be separated from their value
either with a space, or an equal sign (python/go style). The recognised options
are the following:

+ `-s` or `--sleep` is the (initial) number of seconds to wait between attempts.
  When the maximum (see `--max`) is blank, no exponential backoff will occur and
  the function will wait this many seconds between attempts each time.
+ `-m` or `--max` or `--maximum` is the maximum number of seconds to wait
  between attempts. This is to ensure that attempts will happen anyway, albeit
  very seldom.
+ `-f` or `--factor` or `--multiplier` is the factor to multiply the number of
  seconds to wait between each unsuccessfull attempts. This will be capped at
  `--max`.
+ `-t` or `--timeout` is the number of seconds after which `backoff_loop` should
  give up entirely. Seconds are only counted internally within the function, so
  if the command called takes time, this timeout might be inaccurate. The
  default is an empty string, meaning that there will be no timeout at all and
  that `backoff_loop` will loop forever until the command passed as an argument
  succeeds.
+ `-l` or `--loop` is a short hand to give all the other options above at once.
  The option takes a value formed of tokens separated by the colon `:` sign,
  e.g. `<sleep>:<max>:<factor>:<timeout>` where all except the first token are
  optionals. All tokens correspond to the options as described above. The
  `--loop` option exists mainly as a way to control looping from the value of a
  command-line program option or similar.

When calling a function from the argument passed to `backoff_loop`, you should
arrange for the function to return `0` on success, and `1` in all other cases,
as this is how `backoff_loop` detects that its argument has succeeded and it
should release program execution to the caller.

The following example would loop forever (because it calls `false`), waiting
`1`, `2`, `4`, `8` and forever `10` seconds between attempts.

```shell
backoff_loop --sleep 1 --factor 2 --max 10 -- false
```

The following example does the same. It can avoid the `--` separator because the
argument called does not start with a `-`:

```shell
backoff_loop --sleep 1 --factor 2 --max 10 false
```

Finally, the following does once again the same, but uses the `--loop` option to
specify all features at once. The example does not specify the factor, but this
factor defaults to `2`.

```shell
backoff_loop --loop "1:10" false
```

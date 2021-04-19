# Opinionated, Installable dotfiles

This repository contains a set of opinionated dotfiles, organised in
directories, one per tool. You are welcome to use those files, but might mostly
be interested in the installer. The installer is able to copy a specific set of
files for a given distribution, and will automatically backup existing files
before overwriting them. In addition, when relevant, the installer is also able
to delegate installation procedures per tool, if necessary.

Each tool is represented by a set of files and/or directories in a sub-directory
of this repository (see below). The name of that directory is the name of the
tool, a name that can be used for partial installations. Example names are `git`
or `vscode`. For a given tool, thus sub-directory, and at installation time, all
files starting with a dot `.` and all sub-directories will be (recursively)
copied to the target directory, i.e. often your `$HOME` directory. In addition,
any executable file matching `*.sh` will be executed. This enables tool-specific
installation procedures.

There are two possible origins for the sub-directories regrouping installation
files for a given tool. Under the [`distro`](./distro) sub-directory, there
should be as many distro specific directories as necessary, e.g. `ubuntu` or
`darwin`. Distribution names are always in lowercase. If a tool is found there, files, directories and executables will be taken from the distribution-specific directory. If not, a "generic" installation will be looked for under the root of this repository. This is the most common case!

There are two reserved names that cannot be used for the tools: the name of the
distribution specific sub-directory [`distro`](./distro/) and the
[`lib`](./lib/) at the root.

## Examples

To install all tools for the current platform, performing a backup prior to
overwriting, run the following command:

```shell
./install.sh
```

If you want to see exactly what this would do prior to running the command for
real, you can run the following instead.

```shell
./install.sh --verbose trace --dry-run
```

If you want to only install files for the `bash` tool, run the following
command. It takes the name of the known tool as an argument. In practice, there
can be as many arguments as necessary and these should be glob-style pattern
matching known tools (as in directories) that can be passed to `find`.

```shell
./install.sh bash
```
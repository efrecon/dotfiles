# Opinionated, Installable dotfiles

This repository contains a set of opinionated dotfiles, organised in
directories, one per tool. You are welcome to use those files, but might mostly
be interested in the installer. The installer is able to copy a specific set of
files for a given distribution, and will automatically backup existing files
before overwriting them. In addition, when relevant, the installer is also able
to delegate installation procedures per tool, if necessary.

The organisation of the repository and its dot files is as follows:

* There should be one sub-directory per recognised tool under the root directory
  of this repository. The installer will recursively copy all dot
  files/directories under that directory to your home directory, unless the
  following rule match. In addition, any executable file matching `*.sh` will be
  executed. This enables tool-specific installation procedures.
* Under the [`distro`](./distro) sub-directory, there should be as many distro
  specific directories as necessary, e.g. `ubuntu` or `darwin`. Distribution
  names are always in lowercase. Under those distribution specific
  sub-directories, there can be as many sub-directories as necessary and these
  will work as the tools directories described above. Whenever files for a given
  tools have been copied from a distribution specific directory, they will
  **not** be copied from the set of generic directories.

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
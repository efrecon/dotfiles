# Distribution Specific dotfiles

This directory should contain as many sub-directories as there are distribution
that we need to recognise. A distribution is always in lower-case and also
encompasses platforms (or specific distributions on platforms). Examples are
`darwin` (for MacOS), `mingw` for MinGW on Windows, or `ubuntu`.

Each distribution specific directory should contain as many sub-directories as
necessary, one for each tool that requires distribution-specific knowledge. At
installation time, when a matching sub-directory will be found, it will be
picked up instead of the generic directory directly under the root.

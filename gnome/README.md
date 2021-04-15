# Gnome Extensions

This folder contains a good set of Gnome extensions. Whenever the files are
being copied, schemas need to be recompiled, and the settings for the extensions
need to be reset. All settings for extensions are contained in the file
[`extensions.dconf`](./extensions.dconf) in this directory. The file is **not**
copied as part of the dotfiles installation, since it does not start with a dot.
However, its content is merged from [`extensions.sh`](./extensions.sh).

Whenever some settings in an extension are modified, the content of the
[`extensions.dconf`](./extensions.dconf) file needs to be regenerated (by hand).
Running the following command, from this directory is sufficient.

```shell
dconf dump /org/gnome/shell/extensions/ > ./extensions.dconf"
```

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

## Development

Best way to test on a clean system is to use [x11docker]. You will need a
specific `x11docker/gnome3` image, manually built from
[dockerfile-x11docker-gnome] as `x11docker/gnome3`.

Start by running the following command: this will opens a window with a X11
environment running Gnome.

```bash
x11docker --desktop \
          --init=systemd \
          --backend=podman \
          --share ~/dev/foss/github/efrecon/dotfiles \
          --network \
          -- \
            x11docker/gnome3
```

Then, from within that environment, open a terminal, navigate to the
`~/dev/foss/github/efrecon/dotfiles` directory and run the following command:

```bash
./install.sh -v debug -- gnome
```

  [x11docker]: https://github.com/mviereck/x11docker
  [dockerfile-x11docker-gnome]: https://github.com/efrecon/dockerfile-x11docker-gnome

# VS Code

Visual studio code has a sync feature, but this require logging in at one of the
two existing providers. The existing feature facilitate the synchronisation of
extensions. Code also has a mechanism for [recommending] extensions, but this
cannot trigger recommendations when placed in the user directory. This
repository does not rely on these mechanisms, instead it uses the
`--install-extension` command-line option to install the required serie of
extensions in turns. Once extensions have been installed through this mechanism,
and if they are deemed unecessary, the only way to ensure there removal
everywhere is to add a series of calls to code with the `--uninstall-extension`
command-line option.

  [recommending]: https://code.visualstudio.com/docs/editor/extension-gallery#_workspace-recommended-extensions

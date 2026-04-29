# macOS Files

This directory stores macOS-specific files that do not naturally belong under
`$XDG_CONFIG_HOME` or the shared `dots/config` tree.

Use this for application data and home-scoped configuration that macOS commonly
keeps in paths such as `~/Library/Application Support`, `~/Library/Preferences`,
or app-specific folders directly under `~`.

The directory layout should mirror the final home directory path. For example:

```text
macos/Library/Application Support/Foo/settings.json
-> ~/Library/Application Support/Foo/settings.json
```

Keep cross-platform XDG configuration in `dots/config`.

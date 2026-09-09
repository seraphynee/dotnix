# Native configuration inventory

This directory holds native configuration consumed by Den aspects. `active`
means a source reference exists; deployment still depends on host/user aspect
selection. It does not mean the application loads every shipped theme, plugin,
or optional layout. `dormant` means the retained file has no deployment
reference. `manual` is reserved for documented manual installation.

Paths below are relative to `dots/`. A directory entry covers its descendants
unless an exception is listed. Links point to the owning wiring rather than
to generated files in a user's home directory.

| Path | Status | Consumer / aspect | Notes |
| --- | --- | --- | --- |
| `agents/` | active | [instructions](../modules/shell/ai/instructions.nix), `<shell/ai>` | Shared `.agents` tree, including instructions and skills |
| `opencommit.tmpl` | active | [VCS](../modules/shell/vcs.nix), `<shell/opencommit>` | Rendered through sops-nix |
| `config/1Password/` | active | [1Password](../modules/shell/1password.nix), `<shell/_1password>` | SSH agent configuration |
| `config/aerospace/` | active | [desktop tools](../modules/shell/desktop-tools.nix), `<shell/aerospace>` | Optional aspect; not enabled by every host |
| `config/atuin/config.toml` | dormant | none | Atuin itself is configured inline by `<shell/utils>` |
| `config/biome/` | active | [formatters](../modules/shell/formatters.nix), `<shell/formatters>` | Native formatter config |
| `config/fastfetch/` | active | [Fastfetch](../modules/shell/prompt/fastfetch.nix), `<shell/fastfetch>` | Native presentation config |
| `config/fish/conf.d/` | active | [Fish](../modules/shell/shells/fish.nix), `<shell/fish>` | Explicit source/render mappings; Pisces is sourced from the store |
| `config/fish/env.d/` | active | [environment](../modules/shell/shells/environment.nix), `<shell/env>` | XDG template rendered at evaluation |
| `config/fish/functions/` | active | [Fish](../modules/shell/shells/fish.nix), `<shell/fish>` | Pisces functions |
| `config/fish/fish_plugins` | active | [Fish](../modules/shell/shells/fish.nix), `<shell/fish>` | Deployed plugin list |
| `config/fish/fish_variables` | dormant | none | Retained universal-variable snapshot |
| `config/fish/completions/` | dormant | none | Retained `jw` and `workmux` files; generated completions are configured separately |
| `config/ghostty/` | active | [Ghostty](../modules/apps/terminals/ghostty.nix), `<apps/ghostty>` | Theme assets; main settings are inline |
| `config/git/` | active | [Git helper](../lib/shell/vcs/git.nix), `<shell/vcs>` | Shared ignore file |
| `config/helix/` | active | [terminal editors](../modules/shell/editors.nix), `<shell/helix>` | Includes languages and theme |
| `config/herdr/` | active | [Herdr](../modules/shell/multiplexer/herdr.nix), `<shell/herdr>` | Main config and plugin config tree; shipping plugin config does not install that plugin |
| `config/hunk/` | active | [VCS](../modules/shell/vcs.nix), `<shell/hunk>` | Native config |
| `config/kanata/` | active | [Kanata](../modules/services/hardware/kanata.nix), `<services/kanata>` | Rendered core/chords/row plus explicit part files |
| `config/lla/` | active | [file navigation](../modules/shell/file-navigation.nix), `<shell/lla>` | Native config |
| `config/mango/` | active | [window managers](../modules/desktop/window-manager.nix), `<desktop/wm/mango>` | Native configuration tree |
| `config/nano/` | active | [terminal editors](../modules/shell/editors.nix), `<shell/nano>` | Rendered XDG path |
| `config/niri/` | dormant | none | Retained config; check aspect configuration separately |
| `config/nvim/` | active | [terminal editors](../modules/shell/editors.nix), `<shell/neovim>` | Full Lua config tree; includes supporting docs |
| `config/opencode-thinking/` | active | [AI agents](../modules/shell/ai/agents.nix), `<shell/llm-agents>` | Skills deployed alongside a SOPS-rendered config |
| `config/pet/` | active | [file navigation](../modules/shell/file-navigation.nix), `<shell/pet>` | Config and snippet files |
| `config/rift/` | active | [desktop tools](../modules/shell/desktop-tools.nix), `<shell/rift>` | Native config |
| `config/rumdl/` | active | [formatters](../modules/shell/formatters.nix), `<shell/formatters>` | Native formatter config |
| `config/rustfmt/` | active | [formatters](../modules/shell/formatters.nix), `<shell/formatters>` | Native formatter config |
| `config/sesh/` | dormant | none | Sesh package and Tmux picker are configured separately |
| `config/shellcheckrc.tmpl` | active | [formatters](../modules/shell/formatters.nix), `<shell/formatters>` | Native linter config |
| `config/stylua/` | active | [formatters](../modules/shell/formatters.nix), `<shell/formatters>`; [Treefmt](../nix/treefmt.nix) | Also used by repository formatting |
| `config/superfile/` | active | [file navigation](../modules/shell/file-navigation.nix), `<shell/superfile>` | Native config |
| `config/swaylock/` | dormant | none | Retained lock-screen config |
| `config/taplo/` | active | [formatters](../modules/shell/formatters.nix), `<shell/formatters>` | Preserve current destination mapping |
| `config/television/` | active | [file navigation](../modules/shell/file-navigation.nix), `<shell/television>` | Config, cables, and script |
| `config/tmux/` | active | [Tmux](../modules/shell/multiplexer/tmux.nix), `<shell/tmux>` | Explicit config/style files; picker script is packaged; clipboard config generated separately |
| `config/typos/` | active | [formatters](../modules/shell/formatters.nix), `<shell/formatters>` | Native linter config |
| `config/vscode/` | active | [VS Code](../modules/apps/editors/vscode.nix), `<apps/vscode>` | Settings and key bindings |
| `config/wezterm/` | active | [WezTerm](../modules/apps/terminals/wezterm.nix), `<apps/wezterm>` | Theme assets; main Lua config is inline |
| `config/workmux/` | active | [Workmux](../modules/shell/multiplexer/workmux.nix), `<shell/workmux>` | Native config |
| `config/xdg-desktop-portal/` | dormant | none | Portal configuration is declared inline in `<system/xdg>` |
| `config/yamlfmt/` | active | [formatters](../modules/shell/formatters.nix), `<shell/formatters>` | Native formatter config |
| `config/yazi/` | active | [file navigation](../modules/shell/file-navigation.nix), `<shell/yazi>` | Full config/plugin/flavor tree; includes vendored licenses/docs |
| `config/zed/` | active | [Zed](../modules/apps/editors/zed.nix), `<apps/zed>` | Keymap/tasks copied; settings rendered through sops-nix |
| `config/zellij/` | active | [Zellij](../modules/shell/multiplexer/zellij.nix), `<shell/zellij>` | Config and optional layouts |
| `config/zsh/conf.d/` | active | [Zsh](../modules/shell/shells/zsh.nix), `<shell/zsh>` | Explicit files and third-party subtree |
| `config/zsh/env.d/` | active | [environment](../modules/shell/shells/environment.nix), `<shell/env>` | XDG template |
| `config/zsh/completions/` | dormant | none | Retained `_jw` and `_workmux` completions |
| `config/zsh-abbr/` | active | [Zsh](../modules/shell/shells/zsh.nix), `<shell/zsh>` | Abbreviation list |

Outside this directory, [macOS assets](../macos/README.md) are retained for
manual management. `templates/empty/` is retained but is not a flake template
output. No asset in this inventory is moved or activated by documentation.

When adding configuration, update its owning module and this inventory
together. Do not infer activation from the presence of a directory or an
installed package; follow the explicit source reference and aspect selection.

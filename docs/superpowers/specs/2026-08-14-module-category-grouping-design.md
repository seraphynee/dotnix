# Module Category Grouping Design

## Context

The repository's Den aspects are already independently composable, but the physical Nix module tree is fragmented. The clearest example is `modules/shell`, which contains 36 Nix files even though 22 of them are 25 lines or fewer. Related tools are therefore spread across many files, making the repository slower to scan and navigate.

The VCS and LLM-agent work demonstrates the intended direction: related configuration should have a recognizable category-level roof while individual Den aspects remain independently selectable. This refactor applies that principle consistently across the Nix module layer.

## Goals

- Make the Nix module tree leaner and easier to scan.
- Group related CLI tools and system concerns into semantic category files.
- Preserve every existing Den aspect path and its independent enablement.
- Preserve NixOS, nix-darwin, and Home Manager behavior.
- Keep large implementations readable instead of creating category megafiles.
- Make future configuration placement predictable from the tool's responsibility.

## Non-goals

- Introduce category bundle aspects that enable multiple tools together.
- Change package selections, application settings, secrets, or generated files.
- Rename existing Den aspects, including `<shell/llm_agents>`.
- Reorganize `dots/`, `secrets/`, `scripts/`, documentation outside this spec, or application-native configuration trees.
- Redesign host, user, Disko, desktop, secret, or flake architecture.
- Move implementation into helpers merely to minimize the visible file count.

## Decision

Use balanced semantic grouping. Small and medium related modules will be combined directly. Large configuration remains in its category file when it is still readable; focused helpers are allowed when direct consolidation would create an impractical file. The existing VCS helpers under `lib/shell/vcs/` remain the primary example of that exception.

Physical filenames do not define the public Den interface. Grouped files will continue declaring the same atomic attributes under `den.aspects`, so callers retain paths such as `<shell/yazi>`, `<shell/lazygit>`, and `<apps/firefox>` without receiving unrelated tools.

## Organization Rules

- Category names describe responsibilities rather than implementation mechanisms.
- Category filenames use kebab-case.
- Definitions within a category file use short labeled sections and a stable, readable order.
- Existing module bodies remain unchanged except for the outer syntax needed to place sibling aspects in one file.
- Relative source references remain valid because all direct merges stay within their existing directory.
- The `modules/` and `nix/` import-tree behavior remains unchanged; grouped files replace their source files in the same working-copy change to avoid duplicate aspect definitions.
- No compatibility aliases or temporary duplicate aspects are needed because public aspect names do not change.

## File Map

### Shell

Reduce `modules/shell` from 36 Nix files to 12.

| Destination | Source modules and responsibilities |
| --- | --- |
| `packages.nix` | `00-packages.nix`, `utils.nix`, `my-scripts.nix`; package profiles, configured foundational CLI utilities, and locally packaged scripts |
| `shells.nix` | `bash.nix`, `env.nix`, `fish.nix`, `zsh.nix`; interactive shells and their shared runtime environment |
| `prompt.nix` | `fastfetch.nix`, `starship.nix`; prompt and shell presentation |
| `editors.nix` | `helix.nix`, `nano.nix`, `neovim.nix`; terminal editors |
| `vcs.nix` | Existing VCS facade plus `hunk.nix`, `lazygit.nix`, `opencommit.nix`, and `worktrunk.nix`; VCS configuration and workflows |
| `llm-agents.nix` | Existing LLM agent configuration plus `ai.nix`; agent packages, generated settings, and shared `.agents` content |
| `terminal-workspaces.nix` | `herdr.nix`, `tmux.nix`, `zellij.nix`; persistent terminal and agent workspaces |
| `file-navigation.nix` | `lla.nix`, `pet.nix`, `superfile.nix`, `television.nix`, `yazi.nix`; file navigation, fuzzy selection, and command discovery |
| `nix-tools.nix` | Existing `nix-tools.nix` plus `nh.nix`; Nix authoring, inspection, and rebuild workflows |
| `desktop-tools.nix` | `aerospace.nix`, `espanso.nix`, `msnap.nix`, `ocr.nix`, `rift.nix`; desktop-interaction utilities managed from user/system aspects |
| `1password.nix` | Remains focused because it owns security and SSH-agent integration across platforms |
| `homebrew.nix` | Remains focused because it owns the nix-darwin Homebrew integration |

`modules/shell/vcs.nix` continues importing:

- `lib/shell/vcs/profile.nix`
- `lib/shell/vcs/git.nix`
- `lib/shell/vcs/jujutsu.nix`

The roughly 920 lines in those helpers remain split because putting them literally into the category file would make VCS harder to scan.

### Applications

Reduce `modules/apps` from nine files to four.

| Destination | Source modules |
| --- | --- |
| `browsers.nix` | `chromium.nix`, `firefox.nix`, `zen.nix` |
| `editors.nix` | `datagrip.nix`, `vscode.nix`, `zed.nix` |
| `terminals.nix` | `ghostty.nix`, `wezterm.nix` |
| `discord.nix` | Remains focused; there is no related application aspect to merge |

### System

Reduce `modules/system` from 15 files to six.

| Destination | Source modules and responsibilities |
| --- | --- |
| `hardware.nix` | `audio.nix`, `bluetooth.nix`, `nvidia.nix`, `tpm.nix`; hardware enablement and support |
| `boot.nix` | `bootloader.nix`, `impermanence.nix`; boot flow and persistent-root lifecycle |
| `networking.nix` | Existing `networking.nix` plus `ssh.nix`; base networking, SSH clients, and SSH services |
| `virtualization.nix` | `podman.nix`, `virt.nix`; containers and virtual machines |
| `desktop-support.nix` | `fonts.nix`, `xdg.nix`; desktop-facing system and user integration |
| `platform.nix` | `locale.nix`, `settings.nix`, `wsl.nix`; general platform defaults and platform-specific behavior |

### Services

Reduce `modules/services` from three files to two.

| Destination | Source modules |
| --- | --- |
| `networking.nix` | `cloudflare-warp.nix`, `tailscale.nix` |
| `kanata.nix` | Remains focused because its cross-platform input configuration is already substantial |

### Areas intentionally unchanged

- `modules/desktop`: already grouped around desktop environments, window managers, display management, and shell implementations.
- `modules/disko`: each file is a distinct storage layout.
- `modules/hosts`: physical host boundaries are the correct ownership unit.
- `modules/users`: declarative user identity and selection remain one file per user.
- `modules/secrets`: already centralized around the sops-nix integration and its host-specific providers.
- `nix`: each file owns a distinct flake concern.
- `lib`: only focused implementation helpers belong here; it is not a second module taxonomy.

The resulting `modules/` tree contains 42 Nix files instead of 81.

## Composition and Data Flow

No runtime or evaluation data flow changes. Hosts and users continue selecting the same aspect paths. Den continues composing those atomic aspect values into NixOS, nix-darwin, and Home Manager modules. Grouping affects only which source file declares each attribute.

For example, `modules/shell/file-navigation.nix` will declare several sibling aspects, but selecting `<shell/yazi>` still includes only the Yazi module value. It will not implicitly select `<shell/lla>`, `<shell/pet>`, `<shell/superfile>`, or `<shell/television>`.

Similarly, `modules/system/hardware.nix` may declare audio, Bluetooth, NVIDIA, and TPM aspects together while host includes remain individually controlled.

## Migration Strategy

1. Record the clean `jj` state and the current evaluation/check baseline.
2. Capture a complete inventory of declared Den aspect paths.
3. Consolidate `modules/shell`, format, and run focused evaluation.
4. Consolidate `modules/apps`, format, and run focused evaluation.
5. Consolidate `modules/system`, format, and run focused evaluation.
6. Consolidate `modules/services`, format, and run focused evaluation.
7. Compare the final aspect inventory with the baseline.
8. Run the complete repository verification suite.

Each source module and its destination change together. Because import-tree automatically discovers Nix files, no central import list needs updating. Deleting the replaced files is part of the same structural migration and does not remove their public aspects.

## Error Handling and Risk Controls

The principal risks are an omitted aspect, duplicate aspect, changed module argument, broken relative path, or accidental configuration edit while moving code.

Controls:

- Compare exact before/after aspect-path inventories.
- Preserve the union of module arguments required by merged definitions.
- Keep direct merges in the same directory so existing `../../dots` and adjacent script paths remain valid.
- Evaluate after each domain so failures remain localized.
- Review the final `jj diff` for changed values rather than relying only on successful evaluation.
- Treat any pre-existing check failure as a recorded baseline limitation; the refactor must not introduce a new failure.

No new fallback behavior is introduced. Existing assertion and secret failures must remain unchanged.

## Verification Strategy

### Structural checks

- Confirm all expected destination files exist and every replaced source file is gone.
- Compare the complete Den aspect inventory before and after; it must be identical.
- Search host and user modules to confirm their include paths remain unchanged.
- Inspect `jj diff --stat` and `jj diff` to distinguish moves and wrapping from behavioral edits.

### Formatting and repository checks

- Run `nix fmt` during the migration as needed.
- Run `just treefmt-check` on the final tree.
- Run the focused VCS identity check.
- Run `just check` / `nix flake check --print-build-logs`.

### Cross-platform evaluation

- Evaluate the configured NixOS hosts.
- Evaluate the configured nix-darwin host.
- Evaluate standalone Home Manager output where supported by the recorded baseline.
- If an output is already blocked by an unrelated issue, demonstrate that the failure matches the baseline rather than claiming a new successful evaluation.

## Acceptance Criteria

- `modules/` is reduced from 81 Nix files to 42 according to the approved map.
- All existing Den aspect paths remain present and independently selectable.
- Host and user include lists do not need semantic changes.
- Git and Jujutsu remain under the public VCS roof with focused helpers.
- LLM-agent configuration and shared agent content live together.
- No files outside the Nix module layer change except this design, its implementation plan, and formatting effects directly required by grouped Nix files.
- No package, option, secret path, generated configuration, or platform behavior changes.
- Final checks introduce no failures beyond any explicitly recorded baseline limitation.

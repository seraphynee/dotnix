# Simplified Dendritic Configuration Design

## Context

The repository successfully models multiple NixOS, nix-darwin, and Home
Manager configurations with Den and `flake-file`, but two kinds of accumulated
complexity make routine changes harder than necessary:

1. The root flake declares inputs that are no longer consumed, while the reason
   for retaining package-specific inputs is not documented.
2. Host and user aspects repeat long include lists, obscuring the small set of
   choices that is actually unique to each machine or person.

The generated `flake.nix` currently exposes 47 root inputs and `flake.lock`
contains 104 nodes. The formatter and static-analysis check passes. A baseline
`nix flake check --no-build` also evaluates successfully, with local warnings
for deprecated platform accessors and an existing FZF/Atuin Ctrl-R conflict.

## Goals

- Keep Den, `flake-file`, and the dendritic composition model.
- Prefer the newest usable package when choosing between a dedicated input and
  the repository's pinned `nixpkgs`.
- Remove root inputs that have no active or intended consumer.
- Make host and user files describe roles and exceptions instead of repeating
  implementation details.
- Give each substantial file one clear responsibility without splitting large
  declarative data merely to reduce line counts.
- Preserve the effective configuration of every existing host and user.
- Keep the setup flake-first, cross-platform aware, and compatible with the
  existing SOPS-only secret workflow.

## Non-goals

- Replacing Den or `flake-file` with conventional module wiring.
- Changing package versions merely to reduce the number of inputs.
- Redesigning application settings, shell behavior, secrets, disk layouts, or
  boot policy.
- Resolving the FZF/Atuin Ctrl-R conflict, because that requires a separate
  user-facing keybinding decision.
- Splitting every long file. Starship settings and Herdr plugin definitions are
  long but cohesive and remain together.
- Interacting with an upstream repository.

## Dependency Policy

An input remains dedicated when at least one of these conditions is true:

- its package is newer than the package in pinned `nixpkgs`;
- it exports a NixOS or Home Manager module used by this repository;
- `nixpkgs` does not provide the package;
- it provides a pinned source tree rather than a package;
- it is part of the Den, `flake-file`, flake-parts, or platform framework.

Package presence alone is not enough reason to replace an input. The audit
compares the selected package versions and, when equal version strings hide
different revisions, source contents or revisions as well.

### Package comparison at the audited lock state

| Input | Dedicated input | Pinned `nixpkgs` | Decision |
| --- | --- | --- | --- |
| `handy` | 0.9.6 | 0.9.1 | Keep: newer and provides required modules. |
| `hunk` | 0.21.1 | 0.20.1 | Keep: newer and provides the Home Manager module. |
| `mango` | nightly | 0.16.2 | Keep: newer and provides NixOS/Home Manager integration. |
| `noctalia` | 5.0.1 | 4.7.7 | Keep: newer and provides its Home Manager module. |
| `worktrunk` | 0.76.0 | 0.74.0 | Keep: newer. |
| `dms` | 1.6.0 plus a pinned commit date | 1.5.3 (`dms-shell`) | Keep and wire into the dormant DMS aspect. |
| `herdr` | 0.8.2 plus post-release source changes | 0.8.2 release | Keep: the equal version strings do not identify equal source trees. |
| `nixos-anywhere` | 1.13.0 plus post-release source changes | 1.13.0 release | Keep: the equal version strings do not identify equal source trees. |
| `workmux` | pinned upstream commit | unavailable | Keep. The `llm-agents` package is released separately and is not the newest source. |
| `momoi-say` | 0.1.0 | unavailable | Keep. |
| `msnap` | 0.6.1 | unavailable | Keep. |
| `zen-browser` | dedicated packages and Home Manager module | unavailable as `zen-browser` | Keep. |
| `llm-agents` | Codex 0.153.4 and OpenCode 1.18.29 | Codex 0.151.0 and OpenCode 1.18.25 | Keep: selected agents are newer and the input provides agents absent from `nixpkgs`. |

The comparison is evidence for this refactor, not a permanent pin policy.
Future input updates should repeat the comparison rather than treating these
version numbers as timeless.

### Inputs to remove

- `catppuccin`: no Nix input consumer; similarly named native themes and
  plugins are independent.
- `flake-aspects`: no active import or Den dependency in the current wiring.
- `helium`: no package or module consumer; window rules that match Helium's app
  ID do not consume the flake.
- `hjem`: no user or host selects the `hjem` class.
- `niri`: the active aspect uses the NixOS `programs.niri` module and pinned
  `nixpkgs`; the unused flake package also fails against the current nixpkgs API.
- `noctalia-qs`: no direct consumer; the active Noctalia input supplies the
  shell package and module.
- `systems`: no consumer; `nix/den.nix` derives flake systems from `den.hosts`.

`systems-linux` remains because the Hunk input follows it for Bun packaging.
`nixpkgs-lib` remains because flake-parts follows it. Source inputs followed by
other flakes, including `brew-src`, also remain even when application code does
not reference them directly.

## Composition Architecture

Atomic aspects remain the reusable implementation boundary. Two cross-cutting
composition aspects reduce repetition without hiding host-critical settings.

### `<profile/workstation>`

This platform-neutral profile describes a workstation role. Initially it
composes the behavior shared by `acerus` and `esquire`:

- system audio, fonts, locale, networking, settings, SSH client/server,
  virtualization, and XDG integration;
- Mango and Noctalia desktop components;
- Chromium, Discord, Firefox, Ghostty, WezTerm, Zed, and Zen Browser;
- Kanata and Tailscale services.

The profile name intentionally does not mention NixOS. Included atomic aspects
apply only the class-specific configuration they define, so Darwin and Home
Manager behavior can be added to the same profile later.

Storage layouts, bootloaders, impermanence, hardware settings, host secrets,
and host-only applications remain in each host aspect. Specifically:

- `acerus` retains Bluetooth, Handy, Cloudflare WARP, its hardware settings,
  disk layout, boot choice, impermanence, and secrets;
- `esquire` retains NVIDIA, Podman, DataGrip, VS Code, its hardware settings,
  disk layout, boot choice, impermanence, and secrets.

This keeps destructive or machine-sensitive policy visible at the point where
the machine is declared.

### `<feature/development>`

This user-facing feature composes the interactive development environment
shared by `seraphynee` and `micha`:

- development and personal package sets;
- Nix authoring tools and the `nh` rebuild workflow;
- 1Password, shared agent instructions, Bash, Fish, Zsh, and environment setup;
- Lazygit, Neovim, Starship, Tmux, and common command-line utilities.

Shell selection through `<den/user-shell>` remains in the user file. VCS
identity and any additions unique to one person also remain in that person's
aspect. `seraphynee` therefore keeps the extended AI agents, editors, Herdr,
Hunk, navigation tools, scripts, OCR, Workmux, Worktrunk, Yazi, and Zellij
includes explicitly. `micha` becomes primarily the shared feature plus shell
selection. `chianyung` and `admin` are not broadened by this refactor.

Both composition aspects live in `modules/profiles.nix`. The file contains
only descriptions and include lists, making it the central place to answer
"what does this role or feature contain?"

## Readability Changes

- Rename the aspect `llm_agents` to the kebab-case `llm-agents` and update its
  include site.
- Rename constant field `git_user` to idiomatic `gitUser` and update all users
  and characterization assertions.
- Replace deprecated `pkgs.stdenv.isDarwin` and `pkgs.stdenv.isLinux` accessors
  with `pkgs.stdenv.hostPlatform` fields.
- Replace the deprecated `pkgs.system` lookup with
  `pkgs.stdenv.hostPlatform.system`.
- Remove empty `imports` declarations and redundant `with inputs` syntax.
- Add a concise input-retention policy to the README and short rationale
  comments beside exceptional dedicated package inputs. Comments describe the
  reason, not version numbers that will become stale.
- Regenerate `flake.nix` through the existing `write-flake` application rather
  than editing the generated file.

The 391-line Jujutsu module mixes core configuration with a large command
alias registry. Move the alias attribute set to
`lib/shell/vcs/jujutsu-aliases.nix`, leaving enablement, identity, signing,
templates, merge tools, and package selection in `jujutsu.nix`. The helper has
no hidden dependencies and returns only the alias attribute set.

Other long files remain unchanged when their contents are one cohesive data
structure or implementation. This avoids trading line count for additional
navigation and indirection.

## DMS Wiring

The DMS aspect is currently dormant but is retained as an intentional
alternative to Noctalia. It will consume the dedicated input explicitly:

- `programs.dms-shell.package` uses the input's `dms-shell` package;
- `programs.dms-shell.quickshell.package` uses the matching input Quickshell
  package.

This change does not affect current hosts because none includes
`<desktop/qs/dms>`. If enabled later, the aspect uses the newer, internally
matched package set that justifies retaining the input.

## Characterization and Verification

Before composition is changed, add a flake check that asserts representative
effective behavior for both active workstations and the active Seraphynee home
configuration. The check covers:

- Mango and Noctalia enablement on `acerus` and `esquire`;
- Tailscale, Kanata, networking, SSH, and Incus on both workstations;
- Neovim, Fish, Zsh, Nix tooling, and common utilities in the Seraphynee home;
- Acerus- and Esquire-specific features remain distinct.

These are characterization assertions, not a second configuration source. The
existing desktop, bootstrap, VCS, repository, SSH bookmark, Herdr plugin, and
shell-script checks remain authoritative for their focused behavior.

After implementation:

1. Run the repository formatter and static analysis in check mode.
2. Regenerate `flake.nix` only with `nix run .#write-flake`.
3. Update/prune `flake.lock` with the modern flake CLI.
4. Confirm all seven removed inputs are absent from both generated files.
5. Run `nix flake check --no-build --accept-flake-config` to evaluate every
   output and host configuration.
6. Run the full `nix flake check --accept-flake-config --print-build-logs`.
7. Record the new root-input and lock-node counts against the 47/104 baseline.
8. Confirm no file under `secrets/` changed.

The refactor is complete only if the checks pass and no existing host or user
loses a characterized capability. No upstream repository interaction is part
of this work.

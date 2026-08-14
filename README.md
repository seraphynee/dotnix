# dotnix

## Background

Managing personal infrastructure across multiple machines is painful when everything is done manually. This repository exists to make workstation and system setup reproducible, versioned, and fast to recover.

The main problems this repo solves:

- **Reinstall anxiety**: a fresh machine should be bootstrapped quickly, not rebuilt from memory.
- **Configuration drift**: laptop and desktop environments should stay consistent over time.
- **Cross-platform complexity**: NixOS and macOS should share one source of truth where possible.
- **Operational reliability**: installation, rebuild, formatting, and checks should be automated through repeatable commands.
- **Security hygiene**: sensitive values should stay encrypted and managed declaratively.

In short, this repo is needed so infrastructure changes are intentional, auditable, and easy to reproduce.

## Features

- **Single flake, multiple hosts**: manages multiple host targets from one codebase (Linux and Darwin).
- **Declarative system provisioning**: uses Disko-driven layouts, including Btrfs/LUKS-based host setups.
- **Bootstrap-ready install flow**: includes installer-oriented recipes such as `disko-install` and `disko-install-remount` in `justfile`.
- **Modular architecture**: split into reusable modules for hosts, users, system settings, shell tooling, and services.
- **Secrets management with SOPS**: encrypted per-host and shared secrets are tracked safely in-repo.
- **Daily workflow automation**: quality and maintenance commands are centralized (`fmt`, `check`, updates, hooks).
- **Security and CI checks**: GitHub workflows cover linting, flake checks, lockfile updates, and secret scanning.
- **Remote install support**: documented bootstrap SSH flow is available in `docs/nixos-installer-bootstrap-ssh.md`.

## Repository Layout

```text
.
├── nix/          # Flake composition, inputs, tooling, formatting, and checks
├── modules/      # Atomic Den aspects grouped by semantic responsibility
├── lib/          # Focused implementations shared behind module facades
├── dots/         # Native application and shell configuration
├── scripts/      # Reusable operational and packaged scripts
├── secrets/      # Encrypted sops-nix payloads
├── docs/         # Durable operator documentation, designs, and plans
├── macos/        # Manually managed non-XDG macOS application data
└── templates/    # Retained project templates
```

`flake.nix` is generated from the flake-file declarations under `nix/`; edit
those declarations and run `just write-flake` instead of editing `flake.nix`
directly.

## Where New Configuration Belongs

- Add an atomic Den aspect to the matching semantic category under `modules/`.
  Keep its public aspect path independently selectable.
- Put a large focused implementation under `lib/` only when keeping it inside
  its category module would make that module difficult to scan.
- Put native application files under `dots/config/<application>/`, then add an
  explicit module reference. Presence under `dots/` alone does not deploy a
  file.
- Put flake evaluation checks under `nix/checks/`.
- Put reusable operational commands under `scripts/` and expose them through a
  module, the `justfile`, or operator documentation.
- Put secrets under `secrets/` only as encrypted SOPS payloads and declare them
  through sops-nix.
- Put durable Superpowers designs and plans under `docs/superpowers/`. Local
  execution reports, diffs, snapshots, and progress state belong under the
  ignored `.superpowers/sdd/` path.

## Retained but Unwired Assets

Some configuration is intentionally retained without automatic deployment:

- `macos/` contains manually managed application data outside the XDG layout.
- `templates/empty/` is not currently exposed as a flake template output.
- Atuin, Sesh, Swaylock, XDG portal, and Niri files under `dots/config/` are
  dormant or superseded by inline configuration. Check for an explicit source
  reference in `modules/` before treating any native file as active.

## Development Environment

Devenv and Direnv provide the primary repository environment. Run `direnv
allow` after cloning. The flake-native `nix develop` shell remains available
as a separate fallback; the two entry points are intentionally retained rather
than consolidated by the repository-curation refactor.

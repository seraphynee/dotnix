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

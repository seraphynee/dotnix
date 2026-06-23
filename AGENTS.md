# Project Overview
This project is a private, reproducible dotfiles setup for both workstation and server environments. It prioritizes reproducibility by declaring system packages, user packages, shell configurations, editor settings, and secrets management in a single repository. With one `just` command, a fresh machine can be bootstrapped into a fully configured working environment.

## Tech Stack
This repository is built on Nix Flakes. It uses NixOS, nix-darwin, and home-manager for system and user configuration, tied together with the `vic/den` flake framework. `den` organizes configuration into small reusable aspects using a dendritic pattern, so host and user modules can be composed from shared pieces. Shell scripts handle install-time and remote-bootstraps tasks, while `just` provides the main command interface. Secrets are managed with `sops-nix`, and the local development shell is managed by `devenv` and `direnv`.

## Constraints
- **Flakes-first only** : Use nix flake commands and pin everything via flake.lock. No imperative nix-channel or system-wide channels.
- Use only the modern Nix CLI (e.g., `nix build`, `nix shell`, `nix develop`). Avoid using legacy commands such as `nix-shell`, `nix-env` and `nix-channel` to keep the setup reproducible and flake-first.
- **Secrets via `sops-nix` only** : All secrets must be encrypted with `sops-nix`. Plain text secrets must never be commited
- **Cross-platform awareness** : Shared modules should work across NixOS, nix-darwin, and home-manager where applicable; host-specific overrides must live in host aspects.


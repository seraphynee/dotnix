set unstable
set lists

default:
    @just --list

# Quality
fmt-fix:
    nix fmt

fmt-check:
    nix fmt -- --ci

check:
    nix flake check --print-build-logs

secrets-scan:
    nix run nixpkgs#gitleaks -- detect --source . --verbose

ci-check:
    just fmt-check
    just check

# Daily workflow
up target:
    nix flake update {{ target }}

upp:
    nix flake update

write-flake:
    nix run .#write-flake

repl:
    nh os repl

hooks-install:
    lefthook install

clean:
    sudo nix-collect-garbage -d

# Host operations
rb host:
    if [ "$(uname -s)" = "Darwin" ]; then nh darwin switch . -H {{ host }}; else nh os switch . -H {{ host }}; fi

rbb host:
    sudo nixos-rebuild boot --flake .#{{ host }}

# Remote/bootstrap
# Validate a physical NixOS target without changing it
bootstrap-preflight host target *args:
    nix run .#bootstrap -- --host {{ quote(host) }} --target {{ quote(target) }} --preflight {{ quote(args) }}

# Install a physical NixOS target over SSH after preflight and typed confirmation
bootstrap host target *args:
    nix run .#bootstrap -- --host {{ quote(host) }} --target {{ quote(target) }} {{ quote(args) }}

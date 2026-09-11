{ inputs, ... }:
{
  # Per-package version pins via nixpkgs-multiverse.
  #
  # nixpkgs stays the sole system baseline and the target of every
  # `inputs.nixpkgs.follows`. Multiverse is an *additional* input used only
  # for exceptional pins (exact versions, resurrected packages), so we never
  # point `follows` at it: `multiverse.legacyPackages` is an index API, not
  # a package set.
  #
  # Workflow for a new pin:
  #   1. `nix run github:fzakaria/nixpkgs-multiverse#mvs -- query versions <attr>`
  #   2. trial: `...#mvs -- run <attr>@<version> -- --version`
  #   3. add `<attr> = "<version>";` to the `pins` set(s) below.
  #
  # Notes:
  # - The module installs derivations; it never touches `nixpkgs.overlays`,
  #   so it works under `home-manager.useGlobalPkgs = true`. Reach for
  #   `pinOverlay` at NixOS level only if a pin must rewrite `pkgs.<attr>`
  #   globally for other modules' defaults.
  # - Only indexed attributes work: every top-level attr plus children of the
  #   few sets in multiverse's `nix/nested-sets.nix` (e.g. `jetbrains.idea`).
  #   Large sets like `python3Packages.*` / `nodePackages.*` are not indexed.
  # - Unfree packages (vscode, discord, ...) have no fast-path store path and
  #   resolve via the eval path; keep `config.allowUnfree = true` below.
  # - `minimize` (default true) groups pins onto the fewest revisions. A pin
  #   can land on an older build inside its own version run; inspect via
  #   `config.multiverse.plan.groups`.
  den.aspects.system._.multiverse-pins = {
    nixos = {
      imports = [ inputs.multiverse.nixosModules.default ];

      multiverse = {
        enable = true;
        config.allowUnfree = true;

        pins = {
          # Example (leave empty until needed):
          # ripgrep = "13.0.0";
        };
      };
    };

    darwin = {
      imports = [ inputs.multiverse.darwinModules.default ];

      multiverse = {
        enable = true;
        config.allowUnfree = true;

        pins = {
          # Example (leave empty until needed):
          # ripgrep = "13.0.0";
        };
      };
    };

    homeManager = {
      imports = [ inputs.multiverse.homeManagerModules.default ];

      multiverse = {
        enable = true;
        config.allowUnfree = true;

        pins = {
          # Example (leave empty until needed):
          # ripgrep = "13.0.0";
        };
      };
    };
  };
}

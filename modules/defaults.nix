{
  __findFile,
  inputs,
  lib,
  ...
}:
{
  den.default = {
    darwin = {
      system.stateVersion = 6;

      home-manager.backupFileExtension = "backup";
      nix.settings.experimental-features = [
        "nix-command"
        "flakes"
      ];
    };

    nixos =
      { pkgs, ... }:
      {
        system.stateVersion = "25.11";

        # The SOPS CLI is required both for day-to-day secret management and by
        # the repository's bootstrap workflow. Keep it in the base NixOS
        # profile so every NixOS host, including installer variants, gets it.
        environment.systemPackages = [ pkgs.sops ];

        imports = [
          inputs.nix-index-database.nixosModules.nix-index
          inputs.disko.nixosModules.disko
        ];

        nixpkgs.config.allowUnfree = true;
        programs.nix-index-database.comma.enable = true;
        programs.nix-ld.enable = true;

        home-manager = {
          useGlobalPkgs = true;
          useUserPackages = true;
          backupFileExtension = "backup";
        };

        nix = {
          settings = {
            warn-dirty = false;
            extra-system-features = [ "recursive-nix" ];
            experimental-features = [
              "nix-command"
              "flakes"
              "pipe-operators"
              "recursive-nix"
            ];
            trusted-users = [
              "root"
              "@wheel"
            ];
            substituters = [
              "https://cache.nixos.org/"
              "https://nix-community.cachix.org"
              "https://cache.numtide.com"
            ];
            trusted-public-keys = [
              "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
              "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
              "niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g="
            ];
          };
        };
      };

    homeManager =
      { config, pkgs, ... }:
      {
        home.stateVersion = "26.11";
        imports = [ inputs.nix-index-database.homeModules.nix-index ];
        systemd.user.startServices = "sd-switch";

        # Development diagnostics and formatting tools shared by every host.
        home.packages = with pkgs; [
          # LSPs, formatters, and linters
          # dprint # Language-agnostic formatter
          harper
          lychee
          treefmt

          # Text
          codespell
          typos # The Nix package for the typos-cli command.

          # JavaScript and TypeScript
          biome
          eslint
          prettier

          # Go
          gopls

          # Python
          ruff

          # Lua
          luajit
          lua-language-server
          luarocks
          stylua

          # Shell
          shellcheck
          shfmt

          # Nix
          nixfmt

          # Markdown
          markdownlint-cli2
          markdown-oxide
          pandoc

          # TOML
          taplo
          # tombi # TOML formatter and linter

          # YAML
          yamlfmt
          yamllint
        ];

        # Keep pre-26.05 behavior and silence the Home Manager transition warning.
        programs.zsh.dotDir = config.home.homeDirectory;
      };
  };

  den.schema.user.classes = lib.mkDefault [
    "homeManager"
  ];

  den.default.includes = [
    <den/define-user>

    # Autoset hostname
    <lib/define-hostname>
  ];
}

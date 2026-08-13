{
  __findFile,
  inputs,
  ...
}:
{
  den.aspects.shell._.homebrew.darwin =
    { config, ... }:
    {
      assertions = [
        {
          assertion = config.system.primaryUser != null;
          message = "nix-homebrew requires `system.primaryUser` to be set (include <den/primary-user> for the intended user).";
        }
      ];

      imports = [
        inputs.nix-homebrew.darwinModules.nix-homebrew
        {
          nix-homebrew = {
            # Install Homebrew under the default prefix
            enable = true;

            # Apple Silicon Only: Also install Homebrew under the default Intel prefix for Rosetta 2
            enableRosetta = true;

            # User owning the Homebrew prefix
            user = config.system.primaryUser;

            # Automatically migrate existing Homebrew installations
            autoMigrate = true;

            # Declarative tap sources pinned via flake inputs
            taps = {
              "homebrew/homebrew-core" = inputs.homebrew-core;
              "homebrew/homebrew-cask" = inputs.homebrew-cask;
            };
          };

          # Keep nix-darwin's homebrew.taps in sync with nix-homebrew taps.
          homebrew.taps = builtins.attrNames config.nix-homebrew.taps;
        }
      ];
    };
}

{ inputs, ... }:
{
  den.aspects.apps._.chromium = {
    nixos =
      { pkgs, ... }:
      {
        environment.systemPackages = [
          # inputs.helium.packages.${pkgs.stdenv.hostPlatform.system}.default
          pkgs.brave
          # pkgs.google-chrome
        ];
      };
  };
}

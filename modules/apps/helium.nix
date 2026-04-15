{ inputs, ... }:
{
  den.aspects.apps._.helium = {
    nixos =
      { pkgs, ... }:
      {
        environment.systemPackages = [ inputs.helium.packages.${pkgs.stdenv.hostPlatform.system}.default ];
      };
  };
}

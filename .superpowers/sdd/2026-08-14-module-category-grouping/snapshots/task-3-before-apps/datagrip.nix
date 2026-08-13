{ __findFile, ... }:
{
  den.aspects.apps._.datagrip = {
    nixos =
      { pkgs, ... }:
      {
        environment.systemPackages = with pkgs; [
          jetbrains.datagrip
        ];
      };
  };
}

{ __findFile, ... }:
{
  den.aspects.apps._.discord = {
    nixos =
      { pkgs, ... }:
      {
        environment.systemPackages = with pkgs; [
          # legcord
          equibop
        ];
      };

    homeManager = {
      programs.discord.enable = false;
    };
  };
}

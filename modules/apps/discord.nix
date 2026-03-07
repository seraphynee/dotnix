{ __findFile, ... }:
{
  den.aspects.apps._.discord = {
    nixos =
      { pkgs, ... }:
      {
        environment.systemPackages = with pkgs; [ legcord ];
      };

    homeManager = {
      programs.discord.enable = false;
    };
  };
}

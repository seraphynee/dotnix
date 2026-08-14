{ __findFile, ... }:
{
  den.aspects.apps._.discord = {
    nixos =
      { pkgs, ... }:
      {
        environment.systemPackages = with pkgs; [
          equibop
        ];
      };

    homeManager = {
      programs.discord.enable = false;
    };
  };
}

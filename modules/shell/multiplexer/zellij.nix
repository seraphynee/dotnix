{ paths, ... }:
{
  den.aspects.shell._.zellij = {
    homeManager = {
      xdg.configFile."zellij" = {
        source = paths.dots + "/config/zellij";
        recursive = true;
      };
    };

    nixos =
      { pkgs, ... }:
      {
        environment.systemPackages = with pkgs; [ zellij ];
      };
  };
}

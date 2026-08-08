{
  den.aspects.shell._.television.homeManager =
    { pkgs, ... }:
    {
      home.packages = [ pkgs.television ];
      xdg.configFile."television" = {
        source = ../../dots/config/television;
        recursive = true;
      };
    };
}

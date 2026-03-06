{ __findFile, ... }:
{
  den.aspects.apps._.zed = {
    homeManager =
      { pkgs, ... }:
      {
        home.packages = [ pkgs.zed-editor ];

        xdg.configFile."zed" = {
          source = ../../dots/config/zed;
          recursive = true;
        };
      };
  };
}

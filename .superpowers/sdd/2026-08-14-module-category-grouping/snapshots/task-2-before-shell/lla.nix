{
  den.aspects.shell._.lla.homeManager =
    { pkgs, ... }:
    {
      home.packages = [ pkgs.lla ];
      xdg.configFile."lla/config.toml".source = ../../dots/config/lla/config.toml;
    };
}

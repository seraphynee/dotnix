{
  den.aspects.shell._.superfile.homeManager =
    { pkgs, ... }:
    {
      home.packages = [ pkgs.superfile ];
      xdg.configFile."superfile/config.toml".source = ../../dots/config/superfile/config.toml;
    };
}

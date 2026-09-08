{ inputs, paths, ... }:
{
  den.aspects.shell._.workmux.homeManager =
    {
      pkgs,
      ...
    }:
    {
      home.packages = [ inputs.workmux.packages.${pkgs.stdenv.hostPlatform.system}.default ];
      xdg.configFile."workmux/config.yaml".source = paths.dots + "/config/workmux/config.yaml";
    };
}

{ lib, ... }:
{
  den.aspects.shell._.rift = {
    homeManager =
      { pkgs, ... }:
      lib.mkIf pkgs.stdenv.hostPlatform.isDarwin {
        xdg.configFile."rift/config.toml".source = ../../dots/config/rift/config.toml;
      };
  };
}

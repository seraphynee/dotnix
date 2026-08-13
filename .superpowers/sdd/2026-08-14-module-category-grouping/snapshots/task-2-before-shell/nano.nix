{ lib, ... }:
{
  den.aspects.shell._.nano.homeManager =
    { config, pkgs, ... }:
    let
      inherit (pkgs.stdenv.hostPlatform) isDarwin isLinux;
      nanorc = builtins.replaceStrings [ "@XDG_DATA_HOME@" ] [ config.xdg.dataHome ] (
        builtins.readFile ../../dots/config/nano/nanorc
      );
    in
    lib.mkIf (isDarwin || isLinux) {
      home.packages = [ pkgs.nano ];

      xdg.configFile."nano/nanorc".text = nanorc;
    };
}

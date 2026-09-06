{ self, ... }:
{
  perSystem =
    { pkgs, ... }:
    let
      acerusConfig = self.nixosConfigurations.acerus.config;
      acerusHome = acerusConfig.home-manager.users.seraphynee;
      mangoPackage = acerusConfig.programs.mango.package;
      noctaliaPackage = acerusHome.programs.noctalia.package;
      noctaliaConfig = acerusHome.xdg.configFile."noctalia/config.toml".source;
      mangoSessionEnabled = acerusHome.wayland.windowManager.mango.enable or false;
    in
    {
      checks.desktop-stack =
        pkgs.runCommand "desktop-stack-check"
          {
            nativeBuildInputs = [
              mangoPackage
              noctaliaPackage
              pkgs.bash
              pkgs.gnugrep
            ];
          }
          ''
            export DOTNIX_ROOT=${../..}
            export MANGO_BIN=${mangoPackage}/bin/mango
            export NOCTALIA_BIN=${noctaliaPackage}/bin/noctalia
            export NOCTALIA_CONFIG=${noctaliaConfig}
            export MANGO_SESSION_ENABLED=${if mangoSessionEnabled then "true" else "false"}
            bash ${../../tests/desktop-stack.sh}
            touch "$out"
          '';
    };
}

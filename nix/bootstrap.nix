{ lib, ... }:
{
  perSystem =
    { inputs', pkgs, ... }:
    # Keep stale generated flakes evaluable until flake-file regenerates the
    # declared input; do not force a missing input attribute here.
    lib.mkIf
      (
        builtins.hasAttr "nixos-anywhere" inputs'
        && builtins.hasAttr "packages" inputs'.nixos-anywhere
        && inputs'.nixos-anywhere.packages ? nixos-anywhere
      )
      (
        let
          bootstrap = pkgs.writeShellApplication {
            name = "bootstrap";
            runtimeInputs = [
              pkgs.coreutils
              pkgs.gum
              pkgs.jq
              pkgs.nix
              pkgs.openssh
              pkgs.sops
              inputs'.nixos-anywhere.packages.nixos-anywhere
            ];
            text = builtins.readFile ../scripts/nixos-installer.sh;
          };
        in
        {
          packages.bootstrap = bootstrap;
          apps.bootstrap = {
            type = "app";
            program = lib.getExe bootstrap;
          };
          checks.bootstrap-shell =
            pkgs.runCommand "bootstrap-shell-tests"
              {
                nativeBuildInputs = [
                  pkgs.bash
                  pkgs.coreutils
                  pkgs.gnugrep
                  pkgs.just
                  pkgs.jq
                ];
              }
              ''
                bash ${../tests/nixos-installer.sh} ${../scripts/nixos-installer.sh} ${../.}
                touch "$out"
              '';
        }
      );
}

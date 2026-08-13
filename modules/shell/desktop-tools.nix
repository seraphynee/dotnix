{
  __findFile,
  inputs,
  lib,
  ...
}:
{
  # Aerospace
  den.aspects.shell._.aerospace = {
    homeManager = {
      xdg.configFile."aerospace" = {
        source = ../../dots/config/aerospace;
        recursive = true;
      };
    };

    darwin =
      { pkgs, ... }:
      {
        environment.systemPackages = with pkgs; [ aerospace ];
      };
  };
  # Espanso
  den.aspects.shell._.espanso = {
    nixos =
      { pkgs, ... }:
      {
        services.espanso = {
          enable = true;
          package = pkgs.espanso-wayland;
        };
      };

    homeManager =
      { config, ... }:
      let
        espansoSecrets = lib.filterAttrs (name: _: lib.hasPrefix "espanso/" name) config.sops.secrets;
      in
      {
        # Keep espanso runtime under the NixOS module on Wayland so the
        # capability wrapper is applied correctly. Espanso match files remain
        # user-scoped and can safely be wired from decrypted sops secrets.
        xdg.configFile = lib.mapAttrs' (
          name: secret:
          let
            fileName = lib.removePrefix "espanso/" name;
            targetName =
              if lib.hasSuffix ".yml" fileName || lib.hasSuffix ".yaml" fileName then
                fileName
              else
                "${fileName}.yml";
          in
          lib.nameValuePair "espanso/match/${targetName}" {
            source = config.lib.file.mkOutOfStoreSymlink secret.path;
          }
        ) espansoSecrets;
      };
  };
  # Msnap
  den.aspects.shell._.msnap = {
    nixos =
      { pkgs, ... }:
      {
        nixpkgs.overlays = [ inputs.msnap.overlays.default ];
        environment.systemPackages = [ pkgs.msnap ];
      };
  };
  # OCR
  den.aspects.shell._.ocr = {
    nixos =
      { pkgs, lib, ... }:
      {
        environment.systemPackages = [
          (pkgs.writeShellScriptBin "shot-ocr" (
            let
              grim = lib.getExe pkgs.grim;
              slurp = lib.getExe pkgs.slurp;
              tesseract = lib.getExe pkgs.tesseract;
              wlCopy = lib.getExe' pkgs.wl-clipboard "wl-copy";
            in
            ''
              set -euo pipefail

              region="$(${slurp})"
              [ -n "$region" ] || exit 1

              ${grim} -g "$region" - \
                | ${tesseract} stdin stdout -l eng+ind --psm 6 \
                | ${wlCopy} --trim-newline
            ''
          ))
        ];
      };
  };
  # Rift
  den.aspects.shell._.rift = {
    homeManager =
      { pkgs, ... }:
      lib.mkIf pkgs.stdenv.hostPlatform.isDarwin {
        xdg.configFile."rift/config.toml".source = ../../dots/config/rift/config.toml;
      };
  };
}

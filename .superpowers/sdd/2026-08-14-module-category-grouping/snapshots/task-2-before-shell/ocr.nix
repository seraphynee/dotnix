{
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
}

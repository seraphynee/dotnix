{ lib, ... }:
{
  den.aspects.system._.fonts.nixos =
    { pkgs, ... }:
    let
      privateFontPath = /var/lib/private-fonts;
      hasPrivateFont = builtins.pathExists privateFontPath;

      privateFont = pkgs.stdenvNoCC.mkDerivation {
        pname = "private-fonts";
        version = "unstable";
        src = privateFontPath;
        dontConfigure = true;
        dontBuild = true;
        installPhase = ''
          mkdir -p $out/share/fonts/truetype
          mkdir -p $out/share/fonts/opentype
          find . -type f -iname '*.ttf' -exec install -m444 -t $out/share/fonts/truetype {} +
          find . -type f -iname '*.otf' -exec install -m444 -t $out/share/fonts/opentype {} +
        '';
      };

    in
    {
      fonts = {
        fontconfig = {
          enable = true;
          subpixel.rgba = "rgb";
          hinting.enable = true;
          hinting.style = "slight";
          antialias = true;

          defaultFonts = {
            serif = [
              "Noto Serif"
              "Liberation Serif"
            ];
            sansSerif = [
              "Noto Sans"
              "Liberation Sans"
            ];
            monospace = [
              "JetBrains Mono"
              "Liberation Mono"
            ];
            emoji = [ "Noto Color Emoji" ];
          };
        };

        packages =
          with pkgs;
          [
            # Nerd Fonts
            nerd-fonts.fira-code
            nerd-fonts.atkynson-mono
            nerd-fonts.caskaydia-cove
            nerd-fonts.caskaydia-mono
            nerd-fonts.hack
            nerd-fonts.iosevka
            nerd-fonts.jetbrains-mono

            # System fonts
            noto-fonts
            noto-fonts-cjk-sans
            noto-fonts-color-emoji
            liberation_ttf

            # Programming fonts
            jetbrains-mono
            fira-code
            source-code-pro

            # Popular fonts
            roboto
            open-sans
            ubuntu-classic
            martian-mono
            _0xproto
            geist-font
            monaspace
            hack-font

            # Icon fonts
            font-awesome
          ]
          ++ lib.optional hasPrivateFont privateFont;
      };
    };
}

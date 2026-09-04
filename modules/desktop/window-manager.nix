{ __findFile, inputs, ... }:
{
  den.aspects.desktop._.wm = {
    homeManager =
      { pkgs, lib, ... }:
      {
        home.sessionVariables = lib.mkIf pkgs.stdenv.hostPlatform.isLinux {
          XCURSOR_THEME = "Bibata-Modern-Ice";
          XCURSOR_SIZE = 24;
        };
      };
    nixos =
      { pkgs, ... }:
      {
        security.polkit.enable = true;
        services.gnome.gnome-keyring.enable = true;
        services.libinput.enable = true;

        environment.systemPackages = with pkgs; [
          nautilus # File Manager
          bibata-cursors
        ];
      };
    provides = {
      niri = {
        includes = [
          <desktop/wm>
          <desktop/noctalia-greeter>
        ];

        nixos =
          { pkgs, ... }:
          {
            environment.systemPackages = with pkgs; [
              alacritty
              polkit_gnome
            ];

            services.xserver.enable = true;
            services.xserver.xkb.layout = "us";

            programs.niri.enable = true;
            security.polkit.enable = true;
          };

      };

      mango = {
        includes = [
          <desktop/wm>
          <desktop/noctalia-greeter>
          <shell/msnap>
        ];

        homeManager = {
          xdg.configFile."mango" = {
            source = ../../dots/config/mango;
            recursive = true;
          };

        };

        nixos =
          { pkgs, ... }:
          {
            programs.mango = {
              enable = true;
              package = inputs.mango.packages.${pkgs.stdenv.hostPlatform.system}.default;
            };

            environment.systemPackages = with pkgs; [
              # Clipboard Manager
              wl-clipboard
              cliphist
              wl-clip-persist
              tesseract

              # Qt / Input Method
              libsForQt5.qt5ct

              pipewire

              # apps launcher
              fuzzel
            ];
          };
      };
    };
  };
}

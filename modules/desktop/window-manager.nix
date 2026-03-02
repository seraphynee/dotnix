{ __findFile, inputs, ... }:
{
  den.aspects.desktop._.wm = {
    nixos =
      { pkgs, ... }:
      {
        environment.systemPackages = with pkgs; [
          glibc
          wayland
          wayland-protocols
          libinput
          libdrm
          libxkbcommon
          pixman
          meson
          ninja
          libdisplay-info
          libliftoff
          hwdata
          seatd
          pcre2
          xwayland
          libxcb
          fuzzel
        ];
      };
    provides = {
      niri = {
        includes = [ <desktop/sddm> ];

        nixos =
          { pkgs, ... }:
          {
            environment.systemPackages = with pkgs; [
              alacritty
            ];

            services.xserver.enable = true;
            services.xserver.xkb.layout = "us";

            programs.niri.enable = true;
            security.polkit.enable = true;
          };

        # homeManager = {
        #   #      xdg.configFile."niri/config.kdl".source = ../../dots/config/niri/config.kdl;
        # };
      };

      mango = {
        includes = [ <desktop/sddm> ];

        homeManager = {
          xdg.configFile."mango" = {
            source = ../../dots/config/mango;
            recursive = true;
          };

          # imports = [ inputs.mango.hmModules.mango ];
          # wayland.windowManager.mango = {
          #   enable = true;
          #   settings = ''
          #     # mango config.conf
          #     # Monitor
          #     monitorrule=name:eDP-1,width:1920,height:1080,refresh:60,x:0,y:0,scale:1.5
          #     # Bind
          #
          #   '';
          #   autostart_sh = ''
          #     # autostart.sh (tanpa shebang)
          #   '';
          # };
        };

        nixos =
          { pkgs, ... }:
          {
            imports = [
              inputs.mango.nixosModules.mango
            ];

            programs.mango.enable = true;
            xdg.portal = {
              enable = true;
              wlr.enable = true;
              extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
            };

            i18n.inputMethod = {
              enable = true;
              type = "fcitx5";
              fcitx5.addons = with pkgs; [
                fcitx5-gtk
                fcitx5-chinese-addons
              ];
            };

            environment.systemPackages = with pkgs; [
              # Clipboard Manager
              wl-clipboard
              cliphist
              wl-clip-persist

              # Session Utilities
              swaylock

              # Qt / Input Method
              qt5ct

              pipewire
              pipewire-pulse
              xdg-desktop-portal-wlr

              #  GNOME keyring
              gnome-keyring
            ];
          };
      };
    };
  };
}

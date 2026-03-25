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

        environment.systemPackages = with pkgs; [
          # glibc # GNU C runtime library
          # wayland # Core Wayland client/server protocol library
          # wayland-protocols # Extra Wayland protocol definitions
          # libinput # Input device handling (keyboard/mouse/touch)
          # libdrm # DRM/KMS userspace interface for GPUs/displays
          # libxkbcommon # Keyboard layout/keymap handling
          # pixman # Low-level pixel manipulation/compositing library
          # meson # Build system (build-time tool)
          # ninja # Fast build tool used by Meson (build-time)
          # libdisplay-info # DisplayID/EDID parsing library
          # libliftoff # Helper library for DRM plane allocation
          # hwdata # Hardware ID and device data database
          # seatd # Seat/session management daemon for compositors
          # pcre2 # Perl-compatible regular expression library
          # xwayland # X11 compatibility layer on Wayland
          # libxcb # X11 client library (X C Binding)
          # fuzzel # Wayland-native application launcher

          nautilus # File Manager
          bibata-cursors
        ];
      };
    provides = {
      niri = {
        includes = [
          <desktop/sddm>
          <desktop/wm>
        ];

        nixos =
          { pkgs, ... }:
          {
            environment.systemPackages = with pkgs; [
              alacritty
              # gnome-keyring
              polkit_gnome
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
        includes = [
          <desktop/sddm>
          <desktop/wm>
        ];

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

            programs.mango = {
              enable = true;
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

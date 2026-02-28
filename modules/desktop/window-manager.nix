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

      mangowc = {
        includes = [ <desktop/sddm> ];

        nixos =
          { pkgs, ... }:
          {
            imports = [
              inputs.mangowc.nixosModules.mango
              # .. other imports ...
            ];

            programs.mango.enable = true;

            environment.systemPackages = with pkgs; [
              rofi
              foot
              xdg-desktop-portal-wlr
              swaybg
              waybar
              wl-clip-persist
              cliphist
              wl-clipboard
              wlsunset
              xfce-polkit
              swaync
              pamixer
              wlr-dpms
              sway-audio-idle-inhibit-git
              swayidle
              dimland-git
              brightnessctl
              swayosd
              wlr-randr
              grim
              slurp
              satty
              swaylock-effects-git
              wlogout
              sox

            ];
          };

      };
    };
  };
}

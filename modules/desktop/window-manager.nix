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
              foot
              wmenu
              wl-clipboard
              grim
              slurp
              swaybg
              firefox
            ];
          };
      };
    };
  };
}

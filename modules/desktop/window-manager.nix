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
          imports = [ inputs.mango.hmModules.mango ];
          wayland.windowManager.mango = {
            enable = true;
            settings = ''
              # mango config.conf
            '';
            autostart_sh = ''
              # autostart.sh (tanpa shebang)
            '';
          };
        };

        nixos = {
          imports = [
            inputs.mango.nixosModules.mango
          ];

          programs.mango.enable = true;
        };
      };
    };
  };
}

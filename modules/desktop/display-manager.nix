{ inputs, ... }:
{
  den.aspects.desktop._.sddm.nixos =
    { pkgs, ... }:
    let
      flavor = "mocha";
      accent = "lavender";
    in
    {
      environment.systemPackages = [
        (pkgs.catppuccin-sddm.override {
          inherit flavor accent;
        })
      ];
      security.pam.services.sddm.enableGnomeKeyring = true;
      services = {
        xserver.enable = false;

        displayManager.sddm = {
          enable = true;
          extraPackages = [ pkgs.sddm-astronaut ];
          theme = "catppuccin-${flavor}-${accent}";

          # The Weston 15/SDDM Wayland regression was fixed upstream.
          # https://github.com/NixOS/nixpkgs/issues/496361
          wayland.enable = true;

          settings.Theme = {
            CursorTheme = "Bibata-Modern-Ice";
            CursorSize = 24;
          };
        };
      };
    };

  den.aspects.desktop._.noctalia-greeter.nixos =
    { pkgs, ... }:
    {
      imports = [ inputs.noctalia-greeter.nixosModules.default ];

      programs.noctalia-greeter = {
        enable = true;
        settings = {
          cursor = {
            theme = "Bibata-Modern-Ice";
            size = 24;
            path = "${pkgs.bibata-cursors}/share/icons";
          };
          keyboard.layout = "us";
        };
      };

      security.pam.services.greetd.enableGnomeKeyring = true;
    };
}

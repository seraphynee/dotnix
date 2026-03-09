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
          flavor = "mocha";
          accent = "lavender";
        })
      ];
      security.pam.services.sddm.enableGnomeKeyring = true;
      services = {
        xserver.enable = true;

        displayManager.sddm = {
          enable = true;
          extraPackages = [ pkgs.sddm-astronaut ];
          theme = "catppuccin-${flavor}-${accent}";

          # TODO: Re-enable SDDM Wayland once this regression is fixed:
          # https://github.com/NixOS/nixpkgs/issues/496361
          wayland.enable = false;

          settings = {
            General = {
              InputMethod = ""; # Disables the virtual keyboard especially because it's showing in x11 display server
            };
          };
        };
      };
    };
}

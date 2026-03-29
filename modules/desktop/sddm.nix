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
        xserver.enable = false;

        displayManager.sddm = {
          enable = true;
          extraPackages = [ pkgs.sddm-astronaut ];
          theme = "catppuccin-${flavor}-${accent}";

          # The Weston 15/SDDM Wayland regression was fixed upstream.
          # https://github.com/NixOS/nixpkgs/issues/496361
          wayland.enable = true;

          # settings = {
          #   General = {
          #     InputMethod = ""; # Disables the virtual keyboard especially because it's showing in x11 display server
          #   };
          # };
        };
      };
    };
}

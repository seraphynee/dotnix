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
      services.displayManager.sddm = {
        enable = true;
        extraPackages = [ pkgs.sddm-astronaut ];
        theme = "catppuccin-${flavor}-${accent}";
        wayland.enable = true;
        settings = {
          General = {
            RememberLastSession = true;
            Session = "mango";
          };
        };
      };
    };
}

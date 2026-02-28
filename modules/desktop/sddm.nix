{
  den.aspects.desktop._.sddm.nixos =
    { pkgs, ... }:
    let
      flavor = "mocha";
      accent = "lavender";
    in
    {
      services.displayManager.defaultSession = "mango";

      environment.systemPackages = [
        (pkgs.catppuccin-sddm.override {
          flavor = "mocha";
          accent = "lavender";
        })
      ];
      services.displayManager.sddm = {
        enable = true;
        extraPackages = [ pkgs.sddm-astronaut ];
        theme = "catppuccin-${flavor}-${accent}";
        wayland.enable = true;
      };
    };
}

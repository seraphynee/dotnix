_:
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
        services.libinput.enable = true;

        environment.systemPackages = with pkgs; [
          nautilus # File Manager
          bibata-cursors
        ];
      };
  };
}

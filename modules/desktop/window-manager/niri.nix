{ __findFile, ... }:
{
  den.aspects.desktop._.wm.provides.niri = {
    includes = [
      <desktop/wm>
      <desktop/noctalia-greeter>
    ];

    nixos =
      { pkgs, ... }:
      {
        environment.systemPackages = with pkgs; [
          alacritty
          polkit_gnome
        ];

        services.xserver.enable = true;
        services.xserver.xkb.layout = "us";

        programs.niri.enable = true;
        security.polkit.enable = true;
      };
  };
}

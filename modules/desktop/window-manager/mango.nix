{
  paths,
  __findFile,
  inputs,
  ...
}:
{
  den.aspects.desktop._.wm.provides.mango = {
    includes = [
      <desktop/wm>
      <desktop/noctalia-greeter>
    ];

    homeManager =
      { pkgs, ... }:
      {
        imports = [ inputs.mango.hmModules.mango ];

        # Keep the native config tree below while using Mango's module for
        # its user-session target and Wayland/DBus integration.
        wayland.windowManager.mango = {
          enable = true;
          package = inputs.mango.packages.${pkgs.stdenv.hostPlatform.system}.default;
        };

        xdg.configFile."mango" = {
          source = paths.dots + "/config/mango";
          recursive = true;
        };
      };

    nixos =
      { pkgs, ... }:
      {
        programs.mango = {
          enable = true;
          package = inputs.mango.packages.${pkgs.stdenv.hostPlatform.system}.default;
        };

        environment.systemPackages = with pkgs; [
          # Clipboard Manager
          wl-clipboard
          cliphist
          wl-clip-persist
          tesseract

          # Qt / Input Method
          libsForQt5.qt5ct

          pipewire

          # apps launcher
          fuzzel
        ];
      };
  };
}

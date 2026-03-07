{ __findFile, inputs, ... }:
{
  den.aspects.desktop._.qs = {
    nixos =
      { pkgs, ... }:
      {
        environment.systemPackages = with pkgs; [ quickshell ];
      };

    provides = {
      noctalia = {
        includes = [ <desktop/qs> ];

        nixos =
          { pkgs, ... }:
          {
            environment.systemPackages = with pkgs; [
              inputs.noctalia.packages.${pkgs.stdenv.hostPlatform.system}.default
              # ... maybe other stuff
            ];
          };
        homeManager =
          { pkgs, ... }:
          {
            imports = [
              inputs.noctalia.homeModules.default
            ];

            # configure options
            programs.noctalia-shell = {
              enable = true;
              systemd.enable = true;
              plugins = {
                sources = [
                  {
                    enabled = true;
                    name = "Official Noctalia Plugins";
                    url = "https://github.com/noctalia-dev/noctalia-plugins";
                  }
                ];
                states = {
                  catwalk = {
                    enabled = true;
                    sourceUrl = "https://github.com/noctalia-dev/noctalia-plugins";
                  };
                  mangowc-layout-switcher = {
                    enabled = true;
                    sourceUrl = "https://github.com/noctalia-dev/noctalia-plugins";
                  };
                  tailscale = {
                    enabled = true;
                    sourceUrl = "https://github.com/noctalia-dev/noctalia-plugins";
                  };
                  polkit-agent = {
                    enabled = true;
                    sourceUrl = "https://github.com/noctalia-dev/noctalia-plugins";
                  };
                  privacy-indicator = {
                    enabled = true;
                    sourceUrl = "https://github.com/noctalia-dev/noctalia-plugins";
                  };
                };
                version = 2;
              };
              # this may also be a string or a path to a JSON file.

              pluginSettings = {
                catwalk = {
                  minimumThreshold = 25;
                  hideBackground = true;
                };
                # this may also be a string or a path to a JSON file.
              };

              settings = {
                # configure noctalia here
                bar = {
                  density = "compact";
                  position = "top";
                  showCapsule = false;
                  widgets = {
                    left = [
                      {
                        id = "ControlCenter";
                        useDistroLogo = true;
                      }
                      {
                        id = "Network";
                      }
                      {
                        id = "Bluetooth";
                      }
                    ];
                    center = [
                      {
                        hideUnoccupied = false;
                        id = "Workspace";
                        labelMode = "none";
                      }
                    ];
                    right = [
                      {
                        alwaysShowPercentage = false;
                        id = "Battery";
                        warningThreshold = 30;
                      }
                      {
                        formatHorizontal = "HH:mm";
                        formatVertical = "HH mm";
                        id = "Clock";
                        useMonospacedFont = true;
                        usePrimaryColor = true;
                      }
                    ];
                  };
                };
                colorSchemes = {
                  useWallpaperColors = false;
                  predefinedScheme = "Vesper";
                  darkMode = true;
                };
                general = {
                  # avatarImage = "/home/drfoobar/.face";
                  # radiusRatio = 0.2;
                  showSessionButtonsOnLockScreen = false;
                };
                location = {
                  monthBeforeDay = true;
                  name = "Jakarta, Indonesia";
                };
                ui = {
                  fontDefault = "Jetbrains Mono";
                };
                idle = {
                  enabled = true;
                };
              };
              # this may also be a string or a path to a JSON file.
            };
          };
      };
      dms = {
        includes = [ <desktop/qs> ];

        nixos = {
          programs.dms-shell.enable = true;
        };
      };
    };
  };
}

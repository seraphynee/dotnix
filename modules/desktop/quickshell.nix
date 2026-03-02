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
        includes = [ <desktop/wm> ];
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
              settings = {
                # configure noctalia here
                bar = {
                  density = "compact";
                  position = "right";
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
                colorSchemes.predefinedScheme = "Monochrome";
                # general = {
                #   avatarImage = "/home/drfoobar/.face";
                #   radiusRatio = 0.2;
                # };
                location = {
                  monthBeforeDay = true;
                  name = "Jakarta, Indonesia";
                };
              };
              # this may also be a string or a path to a JSON file.
            };
          };
      };
      dms = {
        nixos = {
          programs.dms-shell.enable = true;
        };
      };
    };
  };
}

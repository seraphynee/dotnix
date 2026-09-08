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
            ];
          };
        homeManager =
          { pkgs, ... }:
          {
            imports = [
              inputs.noctalia.homeModules.default
            ];

            programs.noctalia = {
              enable = true;
              # Start Noctalia from Mango only to avoid duplicate/racy startup.
              systemd.enable = false;

              settings = {
                battery.warning_threshold = 30;

                bar = {
                  order = [ "main" ];
                  main = {
                    position = "top";
                    capsule = false;
                    start = [
                      "control-center"
                      "bluetooth"
                      "battery"
                    ];
                    center = [
                      "clock"
                      "workspaces"
                    ];
                    end = [
                      "media"
                    ];
                  };
                };

                location = {
                  auto_locate = false;
                  address = "Jakarta, Indonesia";
                };

                shell = {
                  clipboard_enabled = true;
                  font_family = "IoskeleyMonoTerm Nerd Font";
                  time_format = "{:%H:%M}";

                  launcher = {
                    app_grid = false;
                    compact = true;
                  };

                  panel = {
                    transparency_mode = "solid";

                    launcher_placement = "floating";
                    launcher_position = "bottom_center";

                    control_center_placement = "floating";
                    open_near_click_control_center = true;
                  };

                  session = {
                    grid = false;
                    show_shortcuts = true;
                    actions = [
                      {
                        action = "lock";
                        countdown_seconds = 10.0;
                        enabled = true;
                        shortcut = "1";
                      }
                      {
                        action = "lock_and_suspend";
                        countdown_seconds = 10.0;
                        enabled = true;
                        shortcut = "2";
                      }
                      {
                        action = "hibernate";
                        countdown_seconds = 10.0;
                        enabled = true;
                        shortcut = "3";
                      }
                      {
                        action = "reboot";
                        countdown_seconds = 10.0;
                        enabled = true;
                        shortcut = "4";
                      }
                      {
                        action = "logout";
                        countdown_seconds = 10.0;
                        enabled = true;
                        shortcut = "5";
                      }
                      {
                        action = "shutdown";
                        countdown_seconds = 10.0;
                        enabled = true;
                        shortcut = "6";
                        variant = "destructive";
                      }
                    ];
                  };
                };

                system.monitor.enabled = true;

                theme = {
                  mode = "dark";
                  source = "wallpaper";
                  wallpaper_scheme = "m3-content";
                };

                widget = {
                  battery = {
                    type = "battery";
                    display_mode = "glyph";
                    show_label = true;
                  };
                  clock = {
                    type = "clock";
                    format = "{:%H:%M}";
                    vertical_format = "{:%H\n%M}";
                  };
                  workspaces = {
                    type = "workspaces";
                    hide_when_empty = true;
                    label_source = "id";
                    show_labels = true;
                  };
                  cpu = {
                    type = "sysmon";
                    stat = "cpu_usage";
                  };
                  temp = {
                    type = "sysmon";
                    stat = "cpu_temp";
                  };
                  ram = {
                    type = "sysmon";
                    stat = "ram_used";
                  };
                };
              };
            };
          };
      };
    };
  };
}

{ inputs, ... }:
{
  den.aspects.apps._.zen = {
    nixos = {
      environment.etc = {
        "1password/custom_allowed_browsers" = {
          text = ''
            zen
          ''; # or just "zen" if you use unwrapped package
          mode = "0755";
        };
      };
    };
    homeManager =
      {
        pkgs,
        config,
        ...
      }:
      {
        imports = [ inputs.zen-browser.homeModules.default ];
        programs.zen-browser = {
          enable = true;
          suppressXdgMigrationWarning = true;
          darwinDefaultsId = pkgs.lib.mkIf pkgs.stdenv.isDarwin "org.mozilla.firefox.plist";
          profiles.default = rec {
            search = {
              force = true; # Needed for nix to overwrite search settings on rebuild
              default = "google"; # Aliased to duckduckgo, see other aliases in the link above
              engines = {

                nixos_search = {
                  name = "NixOS Search";
                  urls = [
                    {
                      template = "https://search.nixos.org/packages?channel=25.11&query={searchTerms}";
                    }
                  ];

                  icon = "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
                  definedAliases = [ "@nos" ]; # Keep in mind that aliases defined here only work if they start with "@"
                };

                darwin_search = {
                  name = "Darwin Modules Search";
                  urls = [
                    {
                      template = "https://searchix.ovh/options/darwin/search?query={searchTerms}";
                    }
                  ];

                  icon = "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
                  definedAliases = [ "@dw" ]; # Keep in mind that aliases defined here only work if they start with "@"
                };

                hm_search = {
                  name = "Home Manager Search";
                  urls = [
                    {
                      template = "https://home-manager-options.extranix.com/?query={searchTerms}";
                    }
                  ];

                  icon = "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
                  definedAliases = [ "@hm" ]; # Keep in mind that aliases defined here only work if they start with "@"
                };

                mynixos = {
                  name = "My NixOS";
                  urls = [
                    {
                      template = "https://mynixos.com/search?q={searchTerms}";
                    }
                  ];

                  icon = "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
                  definedAliases = [ "@nx" ]; # Keep in mind that aliases defined here only work if they start with "@"
                };
              };
            };
            containersForce = true;
            containers = {
              Business = {
                color = "blue";
                icon = "briefcase";
                id = 1;
              };
              Productivity = {
                color = "blue";
                icon = "tree";
                id = 2;
              };
              Code = {
                color = "yellow";
                icon = "dollar";
                id = 3;
              };
              Personal = {
                color = "yellow";
                icon = "fingerprint";
                id = 4;
              };
            };
            spacesForce = true;
            spaces = {
              Business = {
                id = "9bf4a656-8bd0-4bc8-a5b1-0ee4f06146ff";
                icon = "🚀";
                container = containers.Business.id;
                position = 1000;
                theme = {
                  type = "gradient";
                  colors = [
                    {
                      algorithm = "floating";
                      type = "explicit-lightness";
                      red = 107;
                      green = 126;
                      blue = 148;
                      lightness = 50;
                      position = {
                        x = 51;
                        y = 97;
                      };
                    }
                  ];
                  opacity = 0.5;
                };
              };
              Productivity = {
                id = "4978fdb5-eadf-4ab6-9281-d62f2d2e1eb8";
                icon = "🍃";
                container = containers.Productivity.id;
                position = 2000;
                theme = {
                  type = "gradient";
                  colors = [
                    {
                      algorithm = "floating";
                      type = "explicit-lightness";
                      red = 48;
                      green = 54;
                      blue = 79;
                      lightness = 50;
                      position = {
                        x = 51;
                        y = 97;
                      };
                    }
                  ];
                  opacity = 0.5;
                };
              };
              Code = {
                id = "2d5fb7f4-d5e7-4903-b8ec-35dbd938a540";
                icon = "💻";
                container = containers.Code.id;
                position = 4000;
                theme = {
                  type = "gradient";
                  colors = [
                    {
                      algorithm = "floating";
                      type = "explicit-lightness";
                      red = 38;
                      green = 38;
                      blue = 38;
                      lightness = 50;
                      position = {
                        x = 51;
                        y = 97;
                      };
                    }
                  ];
                  opacity = 0.5;
                };
              };
              Personal = {
                id = "a46d490f-9de8-434f-94dd-b8fc2d8f2dc1";
                icon = "👥";
                container = containers.Personal.id;
                position = 8000;
                theme = {
                  type = "gradient";
                  colors = [
                    {
                      algorithm = "floating";
                      type = "explicit-lightness";
                      red = 75;
                      green = 46;
                      blue = 43;
                      lightness = 50;
                      position = {
                        x = 51;
                        y = 97;
                      };
                    }
                  ];
                  opacity = 0.5;
                };
              };
            };
            keyboardShortcuts = [
              # Change compact mode toggle to Ctrl+Alt+S
              {
                id = "zen-compact-mode-toggle";
                key = "s";
                modifiers =
                  (pkgs.lib.optionalAttrs pkgs.stdenv.isDarwin {
                    alt = true;
                  })
                  // (pkgs.lib.optionalAttrs pkgs.stdenv.isLinux {
                    control = true;
                  });
              }
              {
                id = "zen-new-empty-split-view";
                key = "8";
                modifiers = {
                  control = true;
                  shift = true;
                };
              }
              {
                id = "zen-split-view-unsplit";
                key = ";";
                modifiers = {
                  control = true;
                };
              }
              {
                id = "zen-split-view-vertical";
                key = "=";
                modifiers = {
                  control = true;
                };
              }
              {
                id = "zen-split-view-horizontal";
                key = "-";
                modifiers = {
                  control = true;
                };
              }
              {
                id = "zen-workspace-switch-1";
                key = "1";
                modifiers = {
                  control = true;
                };
              }
              {
                id = "zen-workspace-switch-2";
                key = "2";
                modifiers = {
                  control = true;
                };
              }
              {
                id = "zen-workspace-switch-3";
                key = "3";
                modifiers = {
                  control = true;
                };
              }
              {
                id = "zen-workspace-switch-4";
                key = "4";
                modifiers = {
                  control = true;
                };
              }
              {
                id = "zen-close-all-unpinned-tabs";
                key = "k";
                modifiers = {
                  control = true;
                  shift = true;
                };
              }
              {
                id = "key_webconsole";
                key = "";
                modifiers = {
                  control = false;
                };
              }
            ];
            # Fails activation on schema changes to detect potential regressions
            # Find this in about:config or prefs.js of your profile
            keyboardShortcutsVersion = 16;
          };
        };
      };
  };
}

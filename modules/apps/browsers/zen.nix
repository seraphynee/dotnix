{ inputs, lib, ... }:
{
  den.aspects.apps._.zen = {
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
          darwinDefaultsId = pkgs.lib.mkIf pkgs.stdenv.hostPlatform.isDarwin "org.mozilla.firefox.plist";
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
              Work = {
                color = "yellow";
                icon = "briefcase";
                id = 1;
              };
              Personal = {
                color = "green";
                icon = "tree";
                id = 2;
              };
            };
            keyboardShortcuts = [
              # Change compact mode toggle to Ctrl+Alt+S
              {
                id = "zen-compact-mode-toggle";
                key = "s";
                modifiers =
                  (pkgs.lib.optionalAttrs pkgs.stdenv.hostPlatform.isDarwin {
                    alt = true;
                  })
                  // (pkgs.lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
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
            keyboardShortcutsVersion = 20;
          };
        };
      };
  };
}

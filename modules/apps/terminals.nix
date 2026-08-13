{
  den.aspects.apps._.ghostty.homeManager =
    { pkgs, ... }:
    {
      xdg.configFile."ghostty" = {
        source = ../../dots/config/ghostty;
        recursive = true;

      };

      programs.ghostty = {
        enable = true;
        enableBashIntegration = true;
        enableFishIntegration = false;
        enableZshIntegration = true;
        settings = {
          shell-integration = "detect";
          shell-integration-features = "cursor,sudo,title";

          background-opacity = 1;
          background-blur-radius = 10;
          theme = "oldworld-vibrant";

          cursor-color = "#00FF98";
          cursor-style = "bar";
          cursor-style-blink = false;

          window-padding-x = 11;
          window-padding-y = 11;
          window-title-font-family = "Cascadia Code";

          font-family = if pkgs.stdenv.hostPlatform.isDarwin then "Jetbrains Mono" else "CommitMono";
          font-size = if pkgs.stdenv.hostPlatform.isDarwin then 19 else 13;
          font-thicken = false;
          font-thicken-strength = 150;

          keybind = [
            "alt+shift+t=toggle_quick_terminal"
            "ctrl+shift+h=new_split:left"
            "ctrl+shift+j=new_split:down"
            "ctrl+shift+k=new_split:up"
            "ctrl+shift+l=new_split:right"
            "alt+shift+h=goto_split:left"
            "alt+shift+j=goto_split:down"
            "alt+shift+k=goto_split:up"
            "alt+shift+l=goto_split:right"
          ]
          ++ pkgs.lib.optionals pkgs.stdenv.hostPlatform.isLinux [
            "alt+one=unbind"
            "alt+two=unbind"
            "alt+three=unbind"
            "alt+four=unbind"
            "alt+five=unbind"
            "alt+six=unbind"
            "alt+seven=unbind"
            "alt+eight=unbind"
            "alt+nine=unbind"
          ];

          mouse-hide-while-typing = true;
          copy-on-select = "clipboard";
          confirm-close-surface = false;
          window-save-state = "always";
        }
        // pkgs.lib.optionalAttrs pkgs.stdenv.hostPlatform.isDarwin {
          macos-option-as-alt = true;
          macos-titlebar-style = "hidden";
          macos-titlebar-proxy-icon = "hidden";

          macos-icon = "custom-style";
          macos-icon-ghost-color = "white";
          macos-icon-screen-color = "black";
        };
      };
    };

  den.aspects.apps._.wezterm.homeManager =
    { pkgs, ... }:
    let
      inherit (pkgs.stdenv.hostPlatform) isDarwin;
      fontName = if isDarwin then "Jetbrains Mono" else "Jetbrains Mono";
      fontSize = if isDarwin then 18.7 else 13.5;
      closeTabMods = if isDarwin then "CMD" else "CTRL|SHIFT";
    in
    {
      xdg.configFile."wezterm" = {
        source = ../../dots/config/wezterm;
        recursive = true;
      };

      programs.wezterm = {
        enable = true;

        extraConfig = ''
          local function tab_title(tab_info)
            local title = tab_info.tab_title
            if title and #title > 0 then
              return title
            end

            return tab_info.active_pane.title
          end

          wezterm.on("format-tab-title", function(tab, _, _, _, _, max_width)
            local edge_background = "rgba(0,0,0,0)"
            local background = "#5D9AC0"
            local foreground = "#000"
            local solid_left_arrow = wezterm.nerdfonts.ple_left_half_circle_thick
            local solid_right_arrow = wezterm.nerdfonts.ple_upper_left_triangle

            if tab.is_active then
              background = "#F1BB67"
              foreground = "#000"
              solid_left_arrow = wezterm.nerdfonts.ple_lower_right_triangle
            end

            local edge_foreground = background
            local title = wezterm.truncate_right(tab_title(tab), max_width - 1)

            return {
              { Background = { Color = edge_background } },
              { Foreground = { Color = edge_foreground } },
              { Text = solid_left_arrow },
              { Background = { Color = background } },
              { Foreground = { Color = foreground } },
              { Text = title },
              { Background = { Color = edge_background } },
              { Foreground = { Color = edge_foreground } },
              { Text = solid_right_arrow },
            }
          end)

          return {
            color_schemes = {
              ["oldworld-vibrant"] = require("themes.oldworld-vibrant"),
            },
            color_scheme = "oldworld-vibrant",
            -- font = wezterm.font("${fontName}"),
            font_size = ${builtins.toString fontSize},
            underline_thickness = 2.8,
            max_fps = 120,

            window_background_opacity = 1,
            ${pkgs.lib.optionalString isDarwin "macos_window_background_blur = 8,"}
            window_decorations = "NONE",
            window_frame = {
              font_size = 14.5,
              active_titlebar_bg = "rgba(0,0,0,0)",
              inactive_titlebar_bg = "rgba(0,0,0,0)",
            },

            tab_bar_at_bottom = true,
            hide_tab_bar_if_only_one_tab = true,
            show_new_tab_button_in_tab_bar = false,

            window_close_confirmation = "NeverPrompt",

            keys = {
              {
                key = "w",
                mods = "${closeTabMods}",
                action = wezterm.action.CloseCurrentTab({ confirm = true }),
              },
              {
                key = "Enter",
                mods = "ALT",
                action = wezterm.action.Nop,
              },
            },
          }
        '';
      };
    };
}

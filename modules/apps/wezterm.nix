{
  den.aspects.apps._.wezterm.homeManager =
    { pkgs, ... }:
    let
      inherit (pkgs.stdenv.hostPlatform) isDarwin;
      fontName = if isDarwin then "Jetbrains Mono" else "Jetbrains Mono";
      fontSize = if isDarwin then 18.7 else 12.5;
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
            -- font_size = ${builtins.toString fontSize},
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

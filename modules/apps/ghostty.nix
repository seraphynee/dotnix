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

          background-opacity = 0.8;
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
}

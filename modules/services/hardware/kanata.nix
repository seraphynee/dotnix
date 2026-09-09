{ paths, ... }:
let
  # Keep platform-specific rendering shared so the Darwin aspect can reuse it
  # when its launchd service is implemented.
  mkKanataConfig =
    pkgs:
    let
      conditionalLmetTab =
        if pkgs.stdenv.hostPlatform.isDarwin then
          "  lmet_tab (tap-hold $tap-time $hold-time tab (macro M-tab))"
        else if pkgs.stdenv.hostPlatform.isLinux then
          "  lmet_tab (tap-hold $tap-time $hold-time tab (macro A-tab))"
        else
          "";

      conditionalHomeRowMods =
        if pkgs.stdenv.hostPlatform.isDarwin then
          ''
            d (tap-hold $tap-time $hold-time d lalt)
            f (tap-hold $tap-time $hold-time f lmet)
            k (tap-hold $tap-time $hold-time k lalt)
            j (tap-hold $tap-time $hold-time j lmet)
          ''
        else if pkgs.stdenv.hostPlatform.isLinux then
          ''
            d (tap-hold $tap-time $hold-time d lmet)
            f (tap-hold $tap-time $hold-time f lalt)
            k (tap-hold $tap-time $hold-time k lmet)
            j (tap-hold $tap-time $hold-time j lalt)
          ''
        else
          "";

      conditionalMVMods =
        if pkgs.stdenv.hostPlatform.isDarwin then
          ''
            m (tap-hold $tap-time $hold-time m rmet)
            v (tap-hold $tap-time $hold-time v rmet)
          ''
        else if pkgs.stdenv.hostPlatform.isLinux then
          ''
            m (tap-hold $tap-time $hold-time m lmet)
            v (tap-hold $tap-time $hold-time v lmet)
          ''
        else
          "";

      conditionalInputChords =
        if pkgs.stdenv.hostPlatform.isDarwin then
          ''
            ;; (m ,) C-a $input-chord-time all-released ()
            (i o) A-left 20 all-released ()
            (o p) A-right 20 all-released ()
          ''
        else if pkgs.stdenv.hostPlatform.isLinux then
          ''
            ;; (m ,) C-a $input-chord-time all-released ()
            (i o) C-left 20 all-released ()
            (o p) C-right 20 all-released ()
          ''
        else
          "";

      conditionalLyRayc =
        if pkgs.stdenv.hostPlatform.isDarwin then
          "  ly-rayc (tap-hold $tap-time $hold-time r (layer-while-held raycast))"
        else if pkgs.stdenv.hostPlatform.isLinux then
          "  ly-rayc r"
        else
          "";

      conditionalRaycastLayer =
        if pkgs.stdenv.hostPlatform.isDarwin then ''(include "parts/raycast.kbd")'' else "";

      render =
        file: replacements:
        builtins.replaceStrings (builtins.attrNames replacements) (builtins.attrValues replacements) (
          builtins.readFile file
        );
    in
    {
      row = render (paths.dots + "/config/kanata/row.kbd") {
        "@conditional_raycast_include@" = conditionalRaycastLayer;
      };

      core = render (paths.dots + "/config/kanata/parts/core.kbd") {
        "@conditional_lmet_tab@" = conditionalLmetTab;
        "@conditional_home_row_mods@" = conditionalHomeRowMods;
        "@conditional_m_v_mods@" = conditionalMVMods;
        "@conditional_ly_rayc@" = conditionalLyRayc;
      };

      chords = render (paths.dots + "/config/kanata/parts/chords.kbd") {
        "@conditional_input_chords@" = conditionalInputChords;
      };
    };
in
{
  den.aspects.services._.kanata = {
    nixos =
      { pkgs, ... }:
      let
        kanataConfig = mkKanataConfig pkgs;
      in
      {
        environment.systemPackages = with pkgs; [ kanata-with-cmd ];
        environment.etc = {
          "kanata/row.kbd".text = kanataConfig.row;
          "kanata/parts/chords.kbd".text = kanataConfig.chords;
          "kanata/parts/core.kbd".text = kanataConfig.core;
          "kanata/parts/herdr.kbd".source = paths.dots + "/config/kanata/parts/herdr.kbd";
          "kanata/parts/raycast.kbd".source = paths.dots + "/config/kanata/parts/raycast.kbd";
          "kanata/parts/tmux.kbd".source = paths.dots + "/config/kanata/parts/tmux.kbd";
          "kanata/parts/zellij.kbd".source = paths.dots + "/config/kanata/parts/zellij.kbd";
        };

        services.kanata = {
          enable = true;
          package = pkgs.kanata-with-cmd;
          keyboards.default.configFile = "/etc/kanata/row.kbd";
        };

        # Keep the restart behavior from the previous hand-written unit while
        # letting the upstream module provide permissions and hardening.
        systemd.services."kanata-default" = {
          after = [ "systemd-udevd.service" ];
          serviceConfig.Restart = "always";
        };
      };
    darwin = { };
    homeManager = { };
    includes = [ ];
  };
}

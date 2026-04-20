{
  den.aspects.services._.kanata = {
    nixos =
      { pkgs, ... }:
      let
        inherit (pkgs.stdenv.hostPlatform) isDarwin isLinux;

        conditionalLmetTab =
          if isDarwin then
            "  lmet_tab (tap-hold $tap-time $hold-time tab (macro M-tab))"
          else if isLinux then
            "  lmet_tab (tap-hold $tap-time $hold-time tab (macro A-tab))"
          else
            "";

        conditionalHomeRowMods =
          if isDarwin then
            ''
              d (tap-hold $tap-time $hold-time d lalt)
              f (tap-hold $tap-time $hold-time f lmet)
              k (tap-hold $tap-time $hold-time k lalt)
              j (tap-hold $tap-time $hold-time j lmet)
            ''
          else if isLinux then
            ''
              d (tap-hold $tap-time $hold-time d lmet)
              f (tap-hold $tap-time $hold-time f lalt)
              k (tap-hold $tap-time $hold-time k lmet)
              j (tap-hold $tap-time $hold-time j lalt)
            ''
          else
            "";

        conditionalMVMods =
          if isDarwin then
            ''
              m (tap-hold $tap-time $hold-time m rmet)
              v (tap-hold $tap-time $hold-time v rmet)
            ''
          else if isLinux then
            ''
              m (tap-hold $tap-time $hold-time m lmet)
              v (tap-hold $tap-time $hold-time v lmet)
            ''
          else
            "";

        conditionalInputChords =
          if isDarwin then
            ''
              (m ,) C-a $input-chord-time all-released ()
              ;; (i o) A-left 20 all-released ()
              ;; (o p) A-right 20 all-released ()
            ''
          else if isLinux then
            ''
              (m ,) C-a $input-chord-time all-released ()
              (i o) C-left 20 all-released ()
              (o p) C-right 20 all-released ()
              (lalt lsft [) C-S-tab 250 first-release ()
              (lalt lsft ]) C-tab 250 first-release ()
            ''
          else
            "";

        conditionalLyRayc =
          if isDarwin then
            "  ly-rayc (tap-hold $tap-time $hold-time r (layer-while-held raycast))"
          else if isLinux then
            "  ly-rayc r"
          else
            "";

        conditionalRaycastLayer =
          if isDarwin then
            ''
              ;; == RAYCAST ==
              (defalias
                rrain (cmd open "raycast://extensions/lardissone/raindrop-io/search")
                remoj (cmd open "raycast://extensions/raycast/emoji-symbols/search-emoji-symbols")
                rspot (cmd open "raycast://extensions/mattisssa/spotify-player/search")
                ryout (cmd open "raycast://extensions/tonka3000/youtube/search-videos?arguments=%7B%22query%22%3A%22%22%7D")
              )

              (deflayer raycast
                     🔅    🔆    @mc   @sls  @dtn  @dnd  ◀◀    ▶⏸    ▶▶    🔇    🔉    🔊
                grv  XX   XX   XX   XX   XX   XX   XX   XX   XX   XX   XX   XX   XX
                tab  XX   XX   @remoj   XX   XX   XX   XX   XX   XX   XX   XX   XX   XX
                caps XX   XX   XX   XX   XX   XX   @rspot   @rrain   @ryout   XX   XX   XX
                lsft XX   XX   XX   XX   XX   XX   XX   XX   XX   XX   XX
                lctl lmet lalt           spc            ralt rmet rctl
              )
            ''
          else
            "";

        kanataConfig =
          builtins.replaceStrings
            [
              "@conditional_lmet_tab@"
              "@conditional_home_row_mods@"
              "@conditional_m_v_mods@"
              "@conditional_input_chords@"
              "@conditional_ly_rayc@"
              "@conditional_raycast_layer@"
            ]
            [
              conditionalLmetTab
              conditionalHomeRowMods
              conditionalMVMods
              conditionalInputChords
              conditionalLyRayc
              conditionalRaycastLayer
            ]
            (builtins.readFile ../../dots/config/kanata/row.kbd);
      in
      {
        environment.systemPackages = with pkgs; [ kanata-with-cmd ];
        environment.etc."kanata/row.kbd".text = kanataConfig;

        systemd.services.kanata = {
          description = "Kanata Keyboard Remapper";
          wantedBy = [ "multi-user.target" ];
          after = [ "systemd-udevd.service" ];

          serviceConfig = {
            Type = "simple";
            ExecStart = "${pkgs.kanata-with-cmd}/bin/kanata -c /etc/kanata/row.kbd";
            Restart = "always";
          };
        };
      };
    darwin = { };
    homeManager = { };
    includes = [ ];
  };
}

{ paths, ... }:
{
  den.aspects.shell._.tmux.homeManager =
    { pkgs, ... }:
    let
      inherit (pkgs.stdenv.hostPlatform) isDarwin isLinux;

      clipboardBindings =
        if isDarwin then
          ''
            bind -T copy-mode-vi y send-keys -X copy-pipe-and-cancel "pbcopy"
            bind -T copy-mode-vi MouseDragEnd1Pane send-keys -X copy-pipe-and-cancel "pbcopy"
          ''
        else if isLinux then
          ''
            if-shell 'command -v wl-copy' {
                  bind -T copy-mode-vi y send-keys -X copy-pipe-and-cancel "wl-copy"
                  bind -T copy-mode-vi MouseDragEnd1Pane send-keys -X copy-pipe-and-cancel "wl-copy"
                } {
                  if-shell 'command -v xclip' {
                    bind -T copy-mode-vi y send-keys -X copy-pipe-and-cancel "xclip -selection clipboard -in"
                    bind -T copy-mode-vi MouseDragEnd1Pane send-keys -X copy-pipe-and-cancel "xclip -selection clipboard -in"
                  } {
                    if-shell 'command -v xsel' {
                      bind -T copy-mode-vi y send-keys -X copy-pipe-and-cancel "xsel --clipboard --input"
                      bind -T copy-mode-vi MouseDragEnd1Pane send-keys -X copy-pipe-and-cancel "xsel --clipboard --input"
                    }
                  }
                }
          ''
        else
          "";

      seshConnectPickerScript = builtins.replaceStrings [ "#!/usr/bin/env bash\n\n" ] [ "" ] (
        builtins.readFile (paths.dots + "/config/tmux/scripts/sesh-connect-picker.sh")
      );

      seshConnectPicker = pkgs.writeShellApplication {
        name = "sesh-connect-picker";
        runtimeInputs = with pkgs; [
          gnused
          gum
          sesh
        ];
        text = seshConnectPickerScript;
      };
    in
    {
      xdg.configFile."tmux/tmux.conf".source = paths.dots + "/config/tmux/tmux.conf";
      xdg.configFile."tmux/settings.conf".source = paths.dots + "/config/tmux/settings.conf";
      xdg.configFile."tmux/keybind.conf".source = paths.dots + "/config/tmux/keybind.conf";
      xdg.configFile."tmux/clipboard.conf".text = clipboardBindings;
      xdg.configFile."tmux/plugins.conf".source = paths.dots + "/config/tmux/plugins.conf";
      xdg.configFile."tmux/status-bar/style-1.conf".source =
        paths.dots + "/config/tmux/status-bar/style-1.conf";
      xdg.configFile."tmux/status-bar/style-2.conf".source =
        paths.dots + "/config/tmux/status-bar/style-2.conf";
      xdg.configFile."tmux/status-bar/style-3.conf".source =
        paths.dots + "/config/tmux/status-bar/style-3.conf";
      xdg.configFile."tmux/status-bar/style-4.conf".source =
        paths.dots + "/config/tmux/status-bar/style-4.conf";
      xdg.configFile."tmux/status-bar/style-5.conf".source =
        paths.dots + "/config/tmux/status-bar/style-5.conf";

      home.packages = [
        pkgs.tmux
        seshConnectPicker
      ];

    };
}

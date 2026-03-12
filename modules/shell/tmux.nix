{ lib, ... }:
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

      tmuxConfig = builtins.replaceStrings [ "@clipboard_bindings@" ] [ clipboardBindings ] (
        builtins.readFile ../../dots/config/tmux/tmux.conf
      );
    in
    {
      home.packages = [ pkgs.tmux ];

      programs = {
        fish.interactiveShellInit = lib.mkAfter ''
          abbr --add tx tmux
          abbr --add tl "tmux list-sessions"
          abbr --add ts --set-cursor 'tmux new -s "%"'
          abbr --add tksv "tmux kill-server"
        '';
      };
      xdg.configFile."tmux/tmux.conf".text = tmuxConfig;
    };
}

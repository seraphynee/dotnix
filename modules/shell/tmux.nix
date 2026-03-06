{ lib, ... }:
{
  den.aspects.shell._.tmux.homeManager = {
    programs = {
      fish.interactiveShellInit = lib.mkAfter ''
        abbr --add tx tmux
        abbr --add tl "tmux list-sessions"
        abbr --add ts --set-cursor 'tmux new -s "%"'
        abbr --add tksv "tmux kill-server"
      '';

      tmux.enable = true;
    };
    xdg.configFile."tmux/tmux.conf".source = ../../dots/config/tmux/tmux.conf;
  };
}

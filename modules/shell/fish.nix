{
  den.aspects.shell._.fish.homeManager =
    { pkgs, ... }:
    {
      home.packages = [ pkgs.fish ];
      programs = {
        command-not-found.enable = false;
        nix-index-database.comma.enable = true;

        fish = {
          enable = false;
          interactiveShellInit = ''
            abbr --add cl clear
          '';
          functions = {
            tmux = ''
              if test (count $argv) -eq 0
                  set -l dir (basename "$PWD")
                  set -l session (string replace -ra '[^A-Za-z0-9_.-]' '_' -- $dir)
                  test -n "$session"; or set session main

                  if set -q TMUX
                      if command tmux has-session -t "$session" 2>/dev/null
                          command tmux switch-client -t "$session"
                      else
                          command tmux new-session -d -s "$session" -c "$PWD"
                          command tmux switch-client -t "$session"
                      end
                  else
                      command tmux new-session -A -s "$session" -c "$PWD"
                  end
                  return
              end

              command tmux $argv
            '';
          };
          # interactiveShellInit = ''
          #   ${pkgs.any-nix-shell}/bin/any-nix-shell fish --info-right | source
          # '';
        };
      };
    };
}

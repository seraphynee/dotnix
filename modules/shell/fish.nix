{
  den.aspects.shell._.fish.homeManager =
    { pkgs, ... }:
    {
      # home.packages = [ pkgs.fish ];

      xdg.configFile."fish/fish_plugins".source = ../../dots/config/fish/fish_plugins;

      programs = {
        command-not-found.enable = false;
        nix-index-database.comma.enable = true;

        fish = {
          enable = true;
          interactiveShellInit = ''
            set -g fish_greeting
            abbr --add cl clear
          '';
          plugins = [
            {
              name = "fisher";
              src = pkgs.fetchFromGitHub {
                owner = "jorgebucaran";
                repo = "fisher";
                rev = "791da644d33d392216f6b1a9b5fc1e470db6d7f2";
                hash = "sha256-U1yd8m56YrHXrJFkU8xaOglulOGV0iBvwjU/bdf8tqA=";
              };
            }
            # {
            #   name = "pisces";
            #   src = pkgs.fetchFromGitHub {
            #     owner = "laughedelic";
            #     repo = "pisces";
            #     rev = "e45e0869855d089ba1e628b6248434b2dfa709c4";
            #     hash = "sha256-Oou2IeNNAqR00ZT3bss/DbhrJjGeMsn9dBBYhgdafBw=";
            #   };
            # }
          ];
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

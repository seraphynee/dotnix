{
  den.aspects.shell._.fish.homeManager =
    { pkgs, ... }:
    let
      inherit (pkgs.stdenv.hostPlatform) isDarwin isLinux;
      clipboardCommand =
        if isDarwin then
          "pbcopy"
        else if isLinux then
          "wl-copy"
        else
          "";

      commonAliases =
        if isDarwin then
          ''
            function cpwd
                if not command -q ${clipboardCommand}
                    echo "cpwd: ${clipboardCommand} is not available" >&2
                    return 1
                end
                printf '%s' "$PWD" | ${clipboardCommand}
            end

            # === DARWIN ===
            alias caff="caffeinate -ism"           # Run command without letting mac sleep

            alias showdot='defaults write com.apple.finder AppleShowAllFiles TRUE'  # show dot files in Finder
            alias hidedot='defaults write com.apple.finder AppleShowAllFiles FALSE' # hide dot files in Finder
            alias spot-off="sudo launchctl unload -w /System/Library/LaunchDaemons/com.apple.metadata.mds.plist"
            alias spot-on="sudo launchctl load -w /System/Library/LaunchDaemons/com.apple.metadata.mds.plist"
            alias fixmounts="sudo automount -vcu" # Re-mount all shared drives
          ''
        else if isLinux then
          ''
            function cpwd
                if not command -q ${clipboardCommand}
                    echo "cpwd: ${clipboardCommand} is not available" >&2
                    return 1
                end
                printf '%s' "$PWD" | ${clipboardCommand}
            end

            # === LINUX ===
            alias ctl='systemctl'
            alias reboot="sudo systemctl reboot"
            alias sstop="sudo systemctl stop"
            alias sstatus="sudo systemctl status"

            # Start and then view status of service
            function sstart
                sudo systemctl start $argv[1]
                sudo systemctl status $argv[1]
            end

            # Restart and then view status of service
            function srestart
                sudo systemctl restart $argv[1]
                sudo systemctl status $argv[1]
            end

            # Journalctl aliases
            alias logs='sudo journalctl -fu'
            alias logs-all='sudo journalctl -u'
          ''
        else
          "";

      commonAliasesFish = builtins.replaceStrings [ "@common_aliases@" ] [ commonAliases ] (
        builtins.readFile ../../dots/config/fish/conf.d/common_aliases.fish
      );
    in
    {
      # home.packages = [ pkgs.fish ];

      xdg.configFile."fish/fish_plugins".source = ../../dots/config/fish/fish_plugins;
      xdg.configFile."fish/conf.d/colors.fish".source = ../../dots/config/fish/conf.d/colors.fish;
      xdg.configFile."fish/conf.d/atuin.fish".source = ../../dots/config/fish/conf.d/atuin.fish;
      xdg.configFile."fish/conf.d/bat.fish".source = ../../dots/config/fish/conf.d/bat.fish;
      xdg.configFile."fish/conf.d/common_functions.fish".source =
        ../../dots/config/fish/conf.d/common_functions.fish;
      xdg.configFile."fish/conf.d/common_aliases.fish" = {
        text = commonAliasesFish;
      };
      xdg.configFile."fish/conf.d/chezmoi.fish".source = ../../dots/config/fish/conf.d/chezmoi.fish;
      xdg.configFile."fish/conf.d/abbreviations.fish".source =
        ../../dots/config/fish/conf.d/abbreviations.fish;
      xdg.configFile."fish/conf.d/jujutsu.fish".source = ../../dots/config/fish/conf.d/jujutsu.fish;
      xdg.configFile."fish/conf.d/yazi.fish".source = ../../dots/config/fish/conf.d/yazi.fish;
      xdg.configFile."fish/conf.d/pet.fish".source = ../../dots/config/fish/conf.d/pet.fish;
      xdg.configFile."fish/conf.d/sk-git.fish".source = ../../dots/config/fish/conf.d/sk-git.fish;
      xdg.configFile."fish/conf.d/skim.fish".source = ../../dots/config/fish/conf.d/skim.fish;
      xdg.configFile."fish/conf.d/zoxide.fish".source = ../../dots/config/fish/conf.d/zoxide.fish;
      xdg.configFile."fish/completions/just.fish".text = ''
        command just --completions fish | source
      '';

      programs = {
        command-not-found.enable = false;
        nix-index-database.comma.enable = false;

        fish = {
          enable = true;
          interactiveShellInit = ''
            set -g fish_greeting
            abbr --add cl clear
            fish_vi_key_bindings

            # === sesh binding ===
            # Untuk default mode (emacs mode)
            bind \eu 'sesh-connect-picker'

            # Untuk vi mode jika diaktifkan
            bind -M insert \eu 'sesh-connect-picker'
            bind -M default \eu 'sesh-connect-picker'

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

{
  __findFile,
  inputs,
  lib,
  ...
}:
{
  # Herdr
  den.aspects.shell._.herdr = {
    homeManager =
      { pkgs, ... }:
      let
        herdr = inputs.herdr.packages.${pkgs.stdenv.hostPlatform.system}.herdr;
        herdrFishCompletion = pkgs.runCommand "herdr-fish-completion" { } ''
          ${herdr}/bin/herdr completion fish > $out
        '';
        herdrPluginBootstrap =
          assert lib.versionAtLeast herdr.version "0.8.0";
          assert lib.versionAtLeast pkgs.nodejs.version "22.12.0";
          pkgs.writeShellApplication {
            name = "herdr-plugin-bootstrap";
            runtimeInputs = [
              herdr
              pkgs.git
              pkgs.jq
              pkgs.nodejs
            ];
            text = builtins.readFile ./herdr-plugin-bootstrap.sh;
          };
      in
      {
        xdg.configFile."herdr/config.toml".source = ../../dots/config/herdr/config.toml;
        xdg.configFile."fish/completions/herdr.fish".source = herdrFishCompletion;
        xdg.configFile."fish/conf.d/herdr.fish".text = ''
          if type -q herdr
              ${herdrPluginBootstrap}/bin/herdr-plugin-bootstrap \
                --github herdr-automatic-rename \
                  qu8n/herdr-automatic-rename \
                --github jhochenbaum.hunkdiff \
                  jhochenbaum/herdr-hunk-diff
              for hook in $HOME/.config/herdr/plugins/github/herdr-automatic-rename-*/shell/hook.fish
                  test -r "$hook"; and source "$hook"; and break
              end
          end
        '';
        xdg.configFile."zsh/conf.d/third-party/herdr-automatic-rename.sh".text = ''
          if (( $+commands[herdr] )); then
            ${herdrPluginBootstrap}/bin/herdr-plugin-bootstrap \
              --github herdr-automatic-rename \
                qu8n/herdr-automatic-rename \
              --github jhochenbaum.hunkdiff \
                jhochenbaum/herdr-hunk-diff
            for hook in $HOME/.config/herdr/plugins/github/herdr-automatic-rename-*/shell/hook.zsh(N); do
              source "$hook"
              break
            done
          fi
        '';
      };

    nixos =
      { pkgs, ... }:
      let
        herdr = inputs.herdr.packages.${pkgs.stdenv.hostPlatform.system}.herdr;
      in
      {
        environment.systemPackages = [ herdr ];
      };
  };
  # tmux
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
        builtins.readFile ../../dots/config/tmux/scripts/sesh-connect-picker.sh
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
      xdg.configFile."tmux/tmux.conf".source = ../../dots/config/tmux/tmux.conf;
      xdg.configFile."tmux/settings.conf".source = ../../dots/config/tmux/settings.conf;
      xdg.configFile."tmux/keybind.conf".source = ../../dots/config/tmux/keybind.conf;
      xdg.configFile."tmux/clipboard.conf".text = clipboardBindings;
      xdg.configFile."tmux/plugins.conf".source = ../../dots/config/tmux/plugins.conf;
      xdg.configFile."tmux/status-bar/style-1.conf".source =
        ../../dots/config/tmux/status-bar/style-1.conf;
      xdg.configFile."tmux/status-bar/style-2.conf".source =
        ../../dots/config/tmux/status-bar/style-2.conf;
      xdg.configFile."tmux/status-bar/style-3.conf".source =
        ../../dots/config/tmux/status-bar/style-3.conf;
      xdg.configFile."tmux/status-bar/style-4.conf".source =
        ../../dots/config/tmux/status-bar/style-4.conf;
      xdg.configFile."tmux/status-bar/style-5.conf".source =
        ../../dots/config/tmux/status-bar/style-5.conf;

      home.packages = [
        pkgs.tmux
        seshConnectPicker
      ];

      programs = {
        fish.interactiveShellInit = lib.mkAfter ''
          abbr --add tx tmux
          abbr --add ts --set-cursor 'tmux new -s "%"'
          abbr --add tl "tmux list-sessions"
          abbr --add tkss --set-cursor 'tmux kill-session -t "%"'
          abbr --add tksv "tmux kill-server"
        '';
      };
    };
  # Zellij
  den.aspects.shell._.zellij = {
    homeManager = {
      xdg.configFile."zellij" = {
        source = ../../dots/config/zellij;
        recursive = true;
      };
    };

    nixos =
      { pkgs, ... }:
      {
        environment.systemPackages = with pkgs; [ zellij ];
      };
  };
}

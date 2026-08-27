{
  inputs,
  lib,
  ...
}:
{
  # Herdr
  den.aspects.shell._.herdr = {
    homeManager =
      {
        config,
        lib,
        pkgs,
        ...
      }:
      let
        herdr = inputs.herdr.packages.${pkgs.stdenv.hostPlatform.system}.herdr;
        herdrPluginLib = import ../../lib/shell/herdr-plugins.nix {
          inherit inputs lib pkgs;
        };
        inherit (herdrPluginLib) herdrPlugins;

        # Keep this JSON in the store so the activation script has a direct
        # reference to every pinned plugin root.  mapAttrsToList is stable
        # (it follows the sorted attribute names), making the desired state
        # deterministic across evaluations.
        herdrPluginDesiredState = pkgs.writeText "herdr-plugins-desired.json" (
          builtins.toJSON {
            version = 1;
            plugins = lib.mapAttrsToList (_: plugin: {
              inherit (plugin) id;
              root = toString plugin.root;
              inherit (plugin) enabled;
            }) herdrPlugins;
          }
        );

        herdrFishCompletion = pkgs.runCommand "herdr-fish-completion" { } ''
          ${herdr}/bin/herdr completion fish > $out
        '';

        herdrPluginReconcile =
          assert lib.versionAtLeast herdr.version "0.8.0";
          pkgs.writeShellApplication {
            name = "herdr-plugin-reconcile";
            runtimeInputs = [
              herdr
              pkgs.bash
              pkgs.coreutils
              pkgs.jq
            ];
            text = builtins.readFile ./herdr-plugin-reconcile.sh;
          };

        automaticRename =
          assert lib.any (plugin: plugin.id == "herdr-automatic-rename") (lib.attrValues herdrPlugins);
          lib.findFirst (plugin: plugin.id == "herdr-automatic-rename") null (lib.attrValues herdrPlugins);
        automaticRenameFishHook = automaticRename.hooks.fish or null;
        automaticRenameZshHook = automaticRename.hooks.zsh or null;
        automaticRenameFishHookPath =
          if automaticRenameFishHook == null then
            ""
          else
            "${toString automaticRename.root}/${automaticRenameFishHook}";
        automaticRenameZshHookPath =
          if automaticRenameZshHook == null then
            ""
          else
            "${toString automaticRename.root}/${automaticRenameZshHook}";
      in
      {
        # The Hunk executable is a Node entrypoint and invokes `node` by name
        # from its manifest.  Keep Node available in interactive HM profiles;
        # no npm or Git tooling is needed at runtime.
        home.packages = [ pkgs.nodejs ];

        home.activation.herdrPlugins = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
          state_home="''${XDG_STATE_HOME:-${config.xdg.stateHome}}"
          ${herdrPluginReconcile}/bin/herdr-plugin-reconcile \
            --desired-state ${herdrPluginDesiredState} \
            --state-file "$state_home/herdr/nix-managed-plugins.json"
        '';

        xdg.configFile."herdr/config.toml".source = ../../dots/config/herdr/config.toml;
        xdg.configFile."fish/completions/herdr.fish".source = herdrFishCompletion;
        xdg.configFile."fish/conf.d/herdr.fish".text = ''
          if type -q herdr; and test -r ${lib.escapeShellArg automaticRenameFishHookPath}
              source ${lib.escapeShellArg automaticRenameFishHookPath}
          end
        '';
        xdg.configFile."zsh/conf.d/third-party/herdr-automatic-rename.sh".text = ''
          if (( $+commands[herdr] )) && [[ -r ${lib.escapeShellArg automaticRenameZshHookPath} ]]; then
            source ${lib.escapeShellArg automaticRenameZshHookPath}
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

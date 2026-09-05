{
  __findFile,
  inputs,
  lib,
  paths,
  ...
}:
{
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
        herdrPluginLib = import (paths.root + "/lib/shell/herdr-plugins.nix") {
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
            text = builtins.readFile (paths.root + "/modules/shell/herdr-plugin-reconcile.sh");
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

        xdg.configFile."herdr/config.toml".source = paths.dots + "/config/herdr/config.toml";
        xdg.configFile."herdr/plugins/config" = {
          source = paths.dots + "/config/herdr/plugins/config";
          recursive = true;
        };
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

          # Stop and delete a Herdr session in one command.
          function hsd() {
            if [[ $# -ne 1 ]]; then
              print -u2 "Usage: hsd <session>"
              return 2
            fi

            local session="$1"
            herdr session stop "$session" && herdr session delete "$session"
          }
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
}

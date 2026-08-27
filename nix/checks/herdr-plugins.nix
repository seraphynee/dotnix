{
  inputs,
  lib,
  ...
}:
{
  perSystem =
    { pkgs, ... }:
    let
      pluginLib = import ../../lib/shell/herdr-plugins.nix {
        inherit inputs lib pkgs;
      };
      inherit (pluginLib) herdrPlugins;

      # Keep the check independent of the attribute name used for the
      # normalized registry entry.  The ID is the compatibility boundary with
      # Herdr's existing registry and is what the reconciler manages.
      hunkDiffPlugin = lib.findFirst (plugin: plugin.id == "jhochenbaum.hunkdiff") null (
        lib.attrValues herdrPlugins
      );

      herdr = inputs.herdr.packages.${pkgs.stdenv.hostPlatform.system}.herdr;
      herdrPluginReconcile = pkgs.writeShellApplication {
        name = "herdr-plugin-reconcile";
        runtimeInputs = [
          herdr
          pkgs.bash
          pkgs.coreutils
          pkgs.jq
        ];
        text = builtins.readFile ../../modules/shell/herdr-plugin-reconcile.sh;
      };

      reconcilerTests =
        pkgs.runCommand "herdr-plugin-reconcile-tests"
          {
            nativeBuildInputs = [
              pkgs.bash
              pkgs.coreutils
              pkgs.jq
            ];
          }
          ''
            export HERDR_PLUGIN_RECONCILE=${herdrPluginReconcile}/bin/herdr-plugin-reconcile
            export HERDR_TEST_BASH=${pkgs.bash}/bin/bash
            bash ${../../tests/herdr-plugin-reconcile.sh}
            touch "$out"
          '';
    in
    {
      # Building this output proves the pinned source, TypeScript build,
      # fixed-output runtime dependency, manifest, and Hunk executable are all
      # available through the flake's fixed-output graph.
      checks.herdr-hunk-diff =
        assert hunkDiffPlugin != null;
        hunkDiffPlugin.root;

      checks.herdr-plugin-reconcile = reconcilerTests;
    };
}

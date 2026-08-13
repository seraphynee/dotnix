{ __findFile, inputs, ... }: {
  den.aspects.shell._.herdr = {
    homeManager =
      { pkgs, ... }:
      let
        herdr = inputs.herdr.packages.${pkgs.stdenv.hostPlatform.system}.herdr;
        herdrAutomaticRename = inputs.herdr-automatic-rename;
        herdrFishCompletion = pkgs.runCommand "herdr-fish-completion" { } ''
          ${herdr}/bin/herdr completion fish > $out
        '';
        herdrPluginBootstrap = pkgs.writeShellApplication {
          name = "herdr-plugin-bootstrap";
          runtimeInputs = [
            herdr
            pkgs.jq
          ];
          text = builtins.readFile ./herdr-plugin-bootstrap.sh;
        };
      in
      {
        xdg.configFile."herdr/config.toml".source = ../../dots/config/herdr/config.toml;
        xdg.configFile."fish/completions/herdr.fish".source = herdrFishCompletion;
        xdg.configFile."fish/conf.d/herdr.fish".text = ''
          if type -q herdr
              ${herdrPluginBootstrap}/bin/herdr-plugin-bootstrap ${herdrAutomaticRename}
              source ${herdrAutomaticRename}/shell/hook.fish
          end
        '';
        xdg.configFile."zsh/conf.d/third-party/herdr-automatic-rename-nix.sh".text = ''
          if (( $+commands[herdr] )); then
            ${herdrPluginBootstrap}/bin/herdr-plugin-bootstrap ${herdrAutomaticRename}
            source "${herdrAutomaticRename}/shell/hook.zsh"
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
}

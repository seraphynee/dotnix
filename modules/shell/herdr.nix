{ __findFile, inputs, ... }: {
  den.aspects.shell._.herdr = {
    homeManager =
      { lib, pkgs, ... }:
      let
        herdr = inputs.herdr.packages.${pkgs.stdenv.hostPlatform.system}.herdr;
        herdrAutomaticRename = inputs.herdr-automatic-rename;
        herdrFishCompletion = pkgs.runCommand "herdr-fish-completion" { } ''
          ${herdr}/bin/herdr completion fish > $out
        '';
      in
      {
        home.activation.herdrAutomaticRename = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
          run ${herdr}/bin/herdr plugin link ${herdrAutomaticRename}
        '';

        xdg.configFile."herdr/config.toml".source = ../../dots/config/herdr/config.toml;
        xdg.configFile."fish/completions/herdr.fish".source = herdrFishCompletion;
        xdg.configFile."fish/conf.d/herdr.fish".text = ''
          if type -q herdr
              source ${herdrAutomaticRename}/shell/hook.fish
          end
        '';
        xdg.configFile."zsh/conf.d/third-party/herdr-automatic-rename-nix.sh".text = ''
          if (( $+commands[herdr] )); then
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

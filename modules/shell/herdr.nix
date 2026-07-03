{ __findFile, inputs, ... }: {
  den.aspects.shell._.herdr = {
    homeManager =
      { pkgs, ... }:
      let
        herdr = inputs.herdr.packages.${pkgs.stdenv.hostPlatform.system}.herdr;
        herdrFishCompletion = pkgs.runCommand "herdr-fish-completion" { } ''
          ${herdr}/bin/herdr completion fish > $out
        '';
      in
      {
        xdg.configFile."herdr/config.toml".source = ../../dots/config/herdr/config.toml;
        xdg.configFile."fish/completions/herdr.fish".source = herdrFishCompletion;
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

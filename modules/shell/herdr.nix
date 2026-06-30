{ __findFile, inputs, ... }: {
  den.aspects.shell._.herdr = {
    homeManager =
      _:
      {
        xdg.configFile."herdr/config.toml".source = ../../dots/config/herdr/config.toml;
      };

    nixos =
      { pkgs, ... }:
      {
        environment.systemPackages = [ inputs.herdr.packages.${pkgs.stdenv.hostPlatform.system}.herdr ];
      };
  };
}

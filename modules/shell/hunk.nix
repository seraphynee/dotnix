{
  __findFile,
  inputs,
  ...
}:
{
  den.aspects.shell._.hunk = {
    homeManager = {
      imports = [
        inputs.hunk.homeManagerModules.default
      ];

      programs.hunk = {
        enable = true;
        enableGitIntegration = false; # Optional: set hunk as default git pager
      };

      xdg.configFile."hunk/config.toml".source = ../../dots/config/hunk/config.toml;
    };
  };
}

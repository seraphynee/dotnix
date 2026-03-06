{
  den.aspects.shell._.lazygit.homeManager = {
    programs.lazygit = {
      enable = true;
      enableFishIntegration = false;
      settings = {
        git = {
          pagers = [
            {
              externalDiffCommand = "difft --color=always";
            }
          ];
        };
      };
    };
  };
}

{
  den.aspects.shell._.lazygit.homeManager = {
    programs.lazygit = {
      enableFishIntegration = false;
      settings = {
        git = {
          pagers = {
            pager = "delta --dark --paging=never";
          };
        };
      };
    };
  };
}

{ lib, ... }:
{
  den.aspects.shell._.lazygit.homeManager = {
    programs.fish.interactiveShellInit = lib.mkAfter ''
      abbr --add lzg lazygit
    '';
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

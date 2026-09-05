{ paths, ... }:
{
  den.aspects.apps._.vscode = {
    homeManager = {
      xdg.configFile."vscode" = {
        source = paths.dots + "/config/vscode";
        recursive = true;
      };
    };
    nixos =
      { pkgs, ... }:
      {
        environment.systemPackages = with pkgs; [
          vscode
          code-cursor
        ];
      };
    darwin =
      { pkgs, ... }:
      {
        environment.systemPackages = with pkgs; [
          vscode
          code-cursor
        ];
      };
  };
}

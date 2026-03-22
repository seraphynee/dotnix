{
  den.aspects.apps._.vscode = {
    homeManager = {
      xdg.configFile."vscode" = {
        source = ../../dots/config/vscode;
        recursive = true;
      };
    };
    nixos =
      { pkgs, ... }:
      {
        environment.systemPackages = with pkgs; [ vscode ];
      };
    darwin =
      { pkgs, ... }:
      {
        environment.systemPackages = with pkgs; [ vscode ];
      };
  };
}

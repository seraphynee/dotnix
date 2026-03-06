{
  perSystem =
    {
      config,
      pkgs,
      inputs',
      ...
    }:
    {
      devShells = {
        default = pkgs.mkShell {
          name = "dotnix-shell";

          packages = with pkgs; [
            just
            lefthook
            gum
          ];
        };
      };
    };
}

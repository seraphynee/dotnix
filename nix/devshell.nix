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
          name = "den-shell";

          packages = with pkgs; [
            nil
            nixd
            nixfmt
            nixfmt-tree
            nixos-anywhere
            gum
          ];
        };
      };
    };
}

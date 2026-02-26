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
            nixfmt
            nixd
            nixos-anywhere
            gum
          ];
        };
      };
    };
}

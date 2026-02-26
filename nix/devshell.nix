{
  perSystem = {
    config,
    pkgs,
    inputs',
    ...
  }: {
    devShells = {
      default = pkgs.mkShell {
        name = "den-shell";

        packages = with pkgs; [
          nil
          alejandra
          nixd
          nixos-anywhere
        ];
      };
    };
  };
}

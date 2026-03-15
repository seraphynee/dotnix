{
  den.aspects.shell._.nix-tools = {
    homeManager =
      { pkgs, ... }:
      {
        home.packages = with pkgs; [
          # Generic Nix authoring and maintenance tools.
          deadnix # Detect unused Nix code
          nil # Nix language server
          nixd # Nix language server
          nixfmt # Nix formatter (RFC style)
          nix-init # Generate a Nix package file from source projects
          nix-inspect # Inspect derivations and Nix metadata
          nixpkgs-review # Build/test packages affected by nixpkgs changes
          nix-tree # View the dependency tree of Nix packages
          nix-update # Automatically update Nix package versions/sources
          nurl # Generate fetcher expressions from source URLs
          statix # Linter for Nix best practices
          vulnix # Scan Nix dependencies for known vulnerabilities
        ];
      };
  };
}

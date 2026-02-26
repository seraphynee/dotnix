{
  den.aspects.shell._.nix-tools = {
    homeManager =
      { pkgs, ... }:
      {
        home.packages = with pkgs; [
          # Nix
          deadnix # Detect unused Nix code
          nix-init # Generate a Nix package file from source projects
          nix-inspect # Inspect derivations and Nix metadata
          nix-output-monitor # Show cleaner Nix build progress output
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

{
  flake-file.inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";

    nixpkgs-lib.follows = "nixpkgs";

    den.url = "github:vic/den";

    flake-file.url = "github:vic/flake-file";

    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs-lib";
    };

    import-tree.url = "github:vic/import-tree";

    systems-linux.url = "github:nix-systems/x86_64-linux";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

  };
}

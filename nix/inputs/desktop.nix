{
  flake-file.inputs = {
    # Dedicated module and newer package than nixpkgs.
    handy.url = "github:cjpais/Handy/v0.9.6";

    # Dedicated module and unavailable package in nixpkgs.
    zen-browser = {
      url = "github:0xc000022070/zen-browser-flake";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };

    # Dedicated module and newer package than nixpkgs.
    noctalia = {
      url = "github:noctalia-dev/noctalia-shell";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Dedicated module for greeter integration.
    noctalia-greeter = {
      url = "github:noctalia-dev/noctalia-greeter";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Dedicated module and newer package than nixpkgs.
    dms = {
      url = "github:AvengeMedia/DankMaterialShell/stable";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Dedicated module and newer package than nixpkgs.
    mango = {
      url = "github:DreamMaoMao/mango";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Package unavailable in nixpkgs.
    msnap = {
      url = "github:atheeq-rhxn/msnap";
      inputs.nixpkgs.follows = "nixpkgs";
    };

  };
}

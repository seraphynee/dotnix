{
  flake-file.inputs = {
    # Package unavailable in nixpkgs.
    momoi-say.url = "github:haruki-nikaidou/momoisay-rs";

    # Newer package than nixpkgs.
    worktrunk = {
      url = "github:max-sixty/worktrunk";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Post-release and newer source than nixpkgs.
    herdr = {
      url = "github:ogulcancelik/herdr";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Source-only inputs for Herdr plugins.
    herdr-automatic-rename = {
      url = "github:qu8n/herdr-automatic-rename";
      flake = false;
    };

    herdr-hunk-diff = {
      url = "github:jhochenbaum/herdr-hunk-diff";
      flake = false;
    };

    herdr-plus = {
      url = "github:cloudmanic/herdr-plus";
      flake = false;
    };

    herdr-worktree-setup = {
      url = "github:tdi/herdr-worktree-setup";
      flake = false;
    };

    herdr-flash = {
      url = "github:youguanxinqing/herdr-flash";
      flake = false;
    };

    herdr-last = {
      url = "github:lmilojevicc/herdr-last";
      flake = false;
    };

    # Newer package than nixpkgs.
    hunk = {
      url = "github:modem-dev/hunk";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.bun2nix.inputs.systems.follows = "systems-linux";
    };

    # Version-pinned packages via nixpkgs-multiverse index.
    # No `inputs.nixpkgs.follows`: multiverse declares `inputs = { }`.
    multiverse.url = "github:fzakaria/nixpkgs-multiverse";

    # Dedicated package set unavailable in nixpkgs.
    llm-agents.url = "github:numtide/llm-agents.nix";

    # Package unavailable in nixpkgs.
    workmux = {
      url = "github:raine/workmux";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
}

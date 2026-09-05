{
  flake-file.inputs = {
    momoi-say.url = "github:haruki-nikaidou/momoisay-rs";

    worktrunk = {
      url = "github:max-sixty/worktrunk";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    herdr = {
      url = "github:ogulcancelik/herdr";
      inputs.nixpkgs.follows = "nixpkgs";
    };

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

    hunk = {
      url = "github:modem-dev/hunk";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.bun2nix.inputs.systems.follows = "systems-linux";
    };

    llm-agents.url = "github:numtide/llm-agents.nix";

    workmux = {
      url = "github:raine/workmux";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
}

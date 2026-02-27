{ inputs, _ }:
let
  hasTreefmt = inputs ? treefmt-nix;
in
{
  imports = [ (if hasTreefmt then inputs.treefmt-nix.flakeModule else { }) ];

  flake-file.inputs = {
    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  perSystem =
    { _ }:
    if hasTreefmt then
      {
        treefmt = {
          projectRootFile = "flake.nix";
          programs.nixfmt.enable = true;
        };
      }
    else
      { };
}

args:
let
  inherit (args) inputs;
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
    _:
    if hasTreefmt then
      {
        treefmt = {
          projectRootFile = "flake.nix";
          programs = {
            # formatter
            nixfmt.enable = true;
            taplo.enable = true;
            yamlfmt.enable = true;
            stylua.enable = true;

            # linter
            statix.enable = true;
            deadnix.enable = true;
          };
        };
      }
    else
      { };
}

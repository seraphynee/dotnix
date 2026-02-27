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
            taplo = {
              enable = true;
              settings = {
                formatting = {
                  align_comments = true;
                  align_entries = true;
                  indent_entries = true;
                  indent_tables = true;
                  reorder_arrays = false;
                  reorder_keys = true;
                };
              };
            };
            yamlfmt.enable = true;
            stylua.enable = true;

            # linter
            statix.enable = true;
            deadnix.enable = true;
          };

          settings.formatter.deadnix.options = [
            "-L"
            "."
          ];
        };
      }
    else
      { };
}

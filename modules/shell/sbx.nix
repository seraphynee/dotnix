_: {
  # Docker Sandboxes CLI (`sbx`), packaged from the official release tarballs.
  # The package is unfree (proprietary); allowUnfree is set in modules/defaults.nix.
  den.aspects.shell._.sbx.homeManager =
    { pkgs, ... }:
    {
      home.packages = [ (pkgs.callPackage ../../pkgs/sbx/package.nix { }) ];
    };
}

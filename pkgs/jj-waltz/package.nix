# jj-waltz (`jw`): a Jujutsu workspace switcher inspired by Worktrunk.
# Upstream is a plain Cargo project (Cargo.lock, no flake.nix), so `src` is the
# non-flake `jj-waltz` flake input.
{
  lib,
  rustPlatform,
  src,
}:

rustPlatform.buildRustPackage {
  pname = "jj-waltz";
  version = (lib.importTOML "${src}/Cargo.toml").package.version;
  inherit src;

  cargoLock.lockFile = "${src}/Cargo.lock";

  # The integration tests drive a real `jj` binary and a pty, which are not
  # available in the Nix build sandbox.
  doCheck = false;

  meta = {
    description = "Jujutsu workspace switcher inspired by Worktrunk";
    homepage = "https://github.com/EzraCerpac/jj-waltz";
    license = lib.licenses.mit;
    mainProgram = "jw";
  };
}

{
  inputs,
  lib,
  pkgs,
}:

let
  # Keep the shape consumed by the Home Manager activation private to this
  # file.  A builder may be a derivation (the common case below) or a function
  # accepting the source; source-only plugins need no builder at all.
  mkHerdrPlugin =
    {
      id,
      src,
      builder ? null,
      enabled ? true,
      fishHook ? null,
      zshHook ? null,
      hooks ? { },
      ...
    }:
    let
      root =
        if builder == null then
          src
        else if builtins.isFunction builder then
          builder src
        else
          builder;

      fish = if fishHook != null then fishHook else hooks.fish or null;
      zsh = if zshHook != null then zshHook else hooks.zsh or null;
    in
    {
      inherit id root enabled;
      hooks =
        (lib.optionalAttrs (fish != null) { inherit fish; })
        // (lib.optionalAttrs (zsh != null) { inherit zsh; });
    };

  hunkDiff =
    let
      smolToml = pkgs.fetchurl {
        url = "https://registry.npmjs.org/smol-toml/-/smol-toml-1.7.1.tgz";
        hash = "sha512-PPlsspAZ4jbMBu5DMFhfUGDQLu/vrL4SyBROVS37x8ynnVmFIs1VPBz1Co8Xks3TvpIaZXmU85y4DrQ+UyVFoQ==";
      };
      hunkRuntime = pkgs.fetchurl {
        url = "https://registry.npmjs.org/hunkdiff/-/hunkdiff-0.18.1.tgz";
        hash = "sha512-5FGaz1P4V/wXY837HhCvaMt/9qa7jFeOzQyi2iH/o+N85LWn9IJN5ONRwIQcsCFwZEVmtQR8/gGpSO5b804MTw==";
      };
      hunkPlatform =
        {
          aarch64-darwin = {
            package = "hunkdiff-darwin-arm64";
            hash = "sha512-+su9a5lTu7V4lmWQ+2yE5J24lKtGiqp0+K4nO+OrM0OVmk0oFHuLlBc5q+rvFD7mQIgXRu04cb2tlMw2OU0eQw==";
          };
          x86_64-darwin = {
            package = "hunkdiff-darwin-x64";
            hash = "sha512-93pUBdwwGDIIijxiNiuphsSRFo0pgrSy91uLkaKV653/fk/btx7XnAaHBGbCdtA8dv+WHyNfjXJZS0UmgmcnBw==";
          };
          aarch64-linux = {
            package = "hunkdiff-linux-arm64";
            hash = "sha512-2DG0o92wX0SpfqftiVJ3P9VMvA2420ZL2LoUh6jfRejsSVpRgbcNhqXNHxwuZWvHZkLXvUBr3/HXK0OLiIJgXw==";
          };
          x86_64-linux = {
            package = "hunkdiff-linux-x64";
            hash = "sha512-wbOdcViuG3lIeSA/cOHqg9EH85PMAdQFphkijM6AYwCLvBU29Xcro2u4liR10HmYQI5DON05CC5wm4142K/QRg==";
          };
        }
        .${pkgs.stdenv.hostPlatform.system}
          or (throw "herdr-hunk-diff: unsupported system ${pkgs.stdenv.hostPlatform.system}");
      hunkPlatformRuntime = pkgs.fetchurl {
        url = "https://registry.npmjs.org/${hunkPlatform.package}/-/${hunkPlatform.package}-0.18.1.tgz";
        inherit (hunkPlatform) hash;
      };
    in
    assert lib.versionAtLeast pkgs.nodejs.version "22.12.0";
    pkgs.stdenvNoCC.mkDerivation {
      pname = "herdr-hunk-diff";
      version = "0.1.0";
      src = inputs.herdr-hunk-diff;

      nativeBuildInputs = [
        pkgs.typescript
      ]
      ++ lib.optionals pkgs.stdenv.hostPlatform.isLinux [ pkgs.autoPatchelfHook ]
      ++ lib.optionals pkgs.stdenv.hostPlatform.isDarwin [
        pkgs.darwin.autoSignDarwinBinariesHook
      ];
      buildInputs = lib.optionals pkgs.stdenv.hostPlatform.isLinux [
        pkgs.stdenv.cc.libc
        (lib.getLib pkgs.stdenv.cc.cc)
      ];

      # TypeScript's noCheck mode is sufficient here: the pinned upstream
      # sources are already type-checked by their own project, and it avoids
      # pulling the complete development dependency graph into this runtime
      # package.  The emitted JavaScript is byte-for-byte equivalent to the
      # normal upstream build for this revision.
      buildPhase = ''
        runHook preBuild
        tsc -p tsconfig.json --noCheck
        runHook postBuild
      '';

      installPhase = ''
        runHook preInstall
        mkdir -p \
          "$out/node_modules/smol-toml" \
          "$out/node_modules/hunkdiff" \
          "$out/node_modules/${hunkPlatform.package}" \
          "$out/node_modules/.bin"
        cp herdr-plugin.toml package.json LICENSE README.md "$out/"
        cp -R dist "$out/"
        tar -xzf ${smolToml} --strip-components=1 -C "$out/node_modules/smol-toml"
        tar -xzf ${hunkRuntime} --strip-components=1 -C "$out/node_modules/hunkdiff"
        tar -xzf ${hunkPlatformRuntime} --strip-components=1 -C "$out/node_modules/${hunkPlatform.package}"
        ln -s ../hunkdiff/bin/hunk.cjs "$out/node_modules/.bin/hunk"
        chmod +x \
          "$out/node_modules/hunkdiff/bin/hunk.cjs" \
          "$out/node_modules/${hunkPlatform.package}/bin/hunk"
        patchShebangs "$out/node_modules/hunkdiff/bin/hunk.cjs"
        runHook postInstall
      '';
    };
in
{
  # This attrset intentionally remains an implementation detail.  Registry
  # identity is the key so mapAttrs consumers emit deterministic desired state
  # without a second public option or ID translation table.
  herdrPlugins = {
    "herdr-automatic-rename" = mkHerdrPlugin {
      id = "herdr-automatic-rename";
      src = inputs.herdr-automatic-rename;
      fishHook = "shell/hook.fish";
      zshHook = "shell/hook.zsh";
    };

    "jhochenbaum.hunkdiff" = mkHerdrPlugin {
      id = "jhochenbaum.hunkdiff";
      src = inputs.herdr-hunk-diff;
      builder = hunkDiff;
    };
  };
}

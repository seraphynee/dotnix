# Docker Sandboxes CLI (`sbx`), repackaged from the official release tarballs
# published at https://github.com/docker/sbx-releases.
#
# The Linux layout mirrors the upstream `install.sh` (PREFIX = $out):
#   bin/sbx                      (statically linked Go binary)
#   libexec/<helpers>            docker-docklet, containerd-shim-nerdbox-*, mkfs.*
#   libexec/{nerdbox-kernel-*,*.erofs}   VM kernel and root filesystem images
#   libexec/lib/libsailor.so
# The Darwin tarball ships a signed `Sbx.app` bundle which is kept untouched
# (modifying it would invalidate the code signature).
#
# Deliberately NOT done on Linux:
#   * The AppArmor profile (`apparmor-profile`) is not installed. It only
#     matters on kernels with kernel.apparmor_restrict_unprivileged_userns=1
#     (Ubuntu 23.10+), which NixOS does not enable by default. It also refers
#     to /usr/libexec paths that do not exist in the Nix store layout.
#   * The GPU passthrough shim (amd64 only) is installed without the suid
#     bit. Enabling GPU passthrough requires running
#     `sudo <store-path>/libexec/containerd-shim-nerdbox-gpu-v1 install`
#     once, manually.
#
# Updating: bump `version`, then refresh each hash with
#   nix store prefetch-file --json \
#     https://github.com/docker/sbx-releases/releases/download/v<version>/<asset>
{
  lib,
  stdenv,
  fetchurl,
  autoPatchelfHook,
  installShellFiles,
  writableTmpDirAsHomeHook,
}:

let
  version = "0.53.0";

  sources = {
    x86_64-linux = {
      asset = "DockerSandboxes-linux-amd64.tar.gz";
      hash = "sha256-qOFx7TMeJIX/jUaXjXv550kpdprKy2dZwVoKZlo7e7I=";
    };
    aarch64-linux = {
      asset = "DockerSandboxes-linux-arm64.tar.gz";
      hash = "sha256-YVqARf5NmGDV0bsw3wGJ4ztePesirvggspR9SwaXQ4s=";
    };
    aarch64-darwin = {
      asset = "DockerSandboxes-darwin.tar.gz";
      hash = "sha256-UfdcfT2Qt1TyKyz7BrduVujrl8eaRQR1Q9XyeRiT5ko=";
    };
  };

  source =
    sources.${stdenv.hostPlatform.system}
      or (throw "sbx: unsupported system ${stdenv.hostPlatform.system}");
in
stdenv.mkDerivation {
  pname = "sbx";
  inherit version;

  src = fetchurl {
    url = "https://github.com/docker/sbx-releases/releases/download/v${version}/${source.asset}";
    inherit (source) hash;
  };

  # Linux tarballs unpack into docker-sbx/; the Darwin one has no top-level dir.
  sourceRoot = if stdenv.hostPlatform.isLinux then "docker-sbx" else ".";

  nativeBuildInputs = [
    installShellFiles
  ]
  ++ lib.optionals stdenv.hostPlatform.isLinux [
    autoPatchelfHook
    # `sbx completion` wants a writable $HOME when run at build time.
    writableTmpDirAsHomeHook
  ];

  # libgcc_s for docker-docklet and libsailor.so; glibc is implicit.
  buildInputs = lib.optionals stdenv.hostPlatform.isLinux [ stdenv.cc.cc.lib ];

  # Never strip: the helpers are Go/Rust binaries and the bundle on Darwin is
  # code signed. Darwin gets no fixup at all for the same reason.
  dontStrip = true;
  dontFixup = stdenv.hostPlatform.isDarwin;
  dontConfigure = true;
  dontBuild = true;

  installPhase =
    if stdenv.hostPlatform.isLinux then
      ''
        runHook preInstall

        install -Dm755 sbx $out/bin/sbx

        for f in docker-docklet containerd-shim-nerdbox-v1 containerd-shim-nerdbox-gpu-v1 mkfs.erofs mkfs.ext4; do
          # The GPU shim only exists in the amd64 tarball.
          [ -f "$f" ] && install -Dm755 "$f" "$out/libexec/$f"
        done

        for f in nerdbox-kernel-* nerdbox-rootfs-*.erofs sailor-rootfs-*.erofs; do
          [ -f "$f" ] && install -Dm644 "$f" "$out/libexec/$f"
        done

        install -Dm755 libsailor.so $out/libexec/lib/libsailor.so

        install -Dm644 LICENSE $out/share/licenses/sbx/LICENSE

        runHook postInstall
      ''
    else
      ''
        runHook preInstall

        mkdir -p $out/Applications $out/bin
        cp -a Sbx.app $out/Applications/Sbx.app

        # Same relative symlinks as the upstream tarball (bin/sbx, bin/llmman).
        ln -s ../Applications/Sbx.app/Contents/MacOS/sbx $out/bin/sbx
        ln -s ../Applications/Sbx.app/Contents/MacOS/llmman $out/bin/llmman

        install -Dm644 LICENSE $out/share/licenses/sbx/LICENSE

        runHook postInstall
      '';

  postInstall =
    if stdenv.hostPlatform.isDarwin then
      ''
        # Completions are bundled in the app.
        installShellCompletion --cmd sbx \
          --bash $out/Applications/Sbx.app/Contents/Resources/completions/bash/sbx \
          --fish $out/Applications/Sbx.app/Contents/Resources/completions/fish/sbx.fish \
          --zsh $out/Applications/Sbx.app/Contents/Resources/completions/zsh/_sbx
      ''
    else
      ''
        # Generated at build time (cobra); the binary is static so it runs as-is.
        installShellCompletion --cmd sbx \
          --bash <($out/bin/sbx completion bash) \
          --fish <($out/bin/sbx completion fish) \
          --zsh <($out/bin/sbx completion zsh)
      '';

  meta = {
    description = "Docker Sandboxes: run AI coding agents in isolated microVMs";
    homepage = "https://github.com/docker/sbx-releases";
    # Proprietary; subject to the Docker Subscription Service Agreement.
    license = lib.licenses.unfree;
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
    mainProgram = "sbx";
    platforms = builtins.attrNames sources;
  };
}

# NDD-95 NixOS Anywhere Bootstrap Design

## Purpose

Consolidate the repository's physical-machine installation paths into one
locked, discoverable, and fail-closed bootstrap application. The application
must validate the selected NixOS configuration, encrypted inputs, SSH target,
and physical disk before it can invoke destructive Disko phases through
`nixos-anywhere`.

The supported operator interface is:

```bash
nix run .#bootstrap -- --host acerus --target root@192.168.1.20
just bootstrap acerus root@192.168.1.20
just bootstrap-preflight acerus root@192.168.1.20
```

`acerus` and `esquire` are physical host names. The bootstrap resolves each
name to its corresponding `*-installer` NixOS configuration automatically.

## Scope

This change covers Acerus and Esquire installation from a NixOS live system,
including host resolution, stable disk validation, SSH authentication, SOPS
age-identity validation and staging, destructive confirmation, flake
packaging, automated tests, and first-boot documentation.

The following are outside this change:

- VPS provisioning, which remains tracked by NDD-64, NDD-65, and NDD-67.
- Automatic creation of a new host aspect or hardware report.
- Automatic switching from the installer profile to the daily profile.
- Automatic firmware Setup Mode changes or TPM enrollment.
- Multi-disk Disko configurations. The supported physical bootstrap requires
  exactly one top-level Disko disk.

## Selected Approach

Retain a shell orchestrator, convert it from Zsh to Bash, and package it with
`pkgs.writeShellApplication`. Bash preserves the useful behavior already in
`scripts/nixos-installer.sh`, is easy to exercise with command stubs, and does
not add an application runtime beyond dependencies supplied by Nix.

A Python rewrite would improve argument parsing but add a runtime and a larger
rewrite without improving the safety boundary. A thin Nix-only wrapper would
not model interactive SSH bootstrap, remote inspection, cleanup, and typed
confirmation clearly enough.

## Flake Integration and Command Surface

Declare `nixos-anywhere` in `nix/dendritic.nix`, following this repository's
generated-flake convention, and make its `nixpkgs` input follow the repository
`nixpkgs`. Regenerate `flake.nix` with `nix run .#write-flake` and update
`flake.lock`; neither the bootstrap nor a Just recipe may fetch an unpinned
GitHub reference at runtime.

Add a flake-parts module under `nix/` that exposes:

- `packages.bootstrap`: a `writeShellApplication` containing the installer
  script and declared runtime inputs.
- `apps.bootstrap`: the default app entry for `nix run .#bootstrap`.
- A flake check that runs the stubbed shell test suite against the packaged
  application.

The runtime closure supplies Bash, Nix, `nixos-anywhere`, Gum, OpenSSH,
SOPS, jq, and coreutils commands used by the script. The script does not probe
for or fall back to an independently installed `nixos-anywhere`. `lsblk` and
`readlink` used for disk inspection execute on the NixOS target over SSH.

Replace the existing `just anywhere` recipe with:

- `bootstrap host target *args`, which invokes `nix run .#bootstrap`.
- `bootstrap-preflight host target *args`, which invokes the same app with
  `--preflight`.

Remove the standalone `disko-mount-only`, `disko-install`,
`disko-install-remount`, and `install-after-key` recipes. They duplicate the
physical bootstrap path, bypass its safety checks, and currently fetch Disko
outside the local lock. The local `bootstrap` app becomes the sole supported
destructive physical-machine entry point. `just --list` must describe both
new commands.

## Command-Line Contract

The application accepts:

- `--host HOST`: required physical host name or an explicit existing
  `HOST-installer` configuration.
- `--target USER@ADDRESS`: required SSH destination.
- `--age-identity PATH`: age identity, defaulting to
  `$HOME/.local/share/ages/keys.txt`.
- `--ssh-auth password|key|bootstrap-key`: authentication strategy,
  defaulting to `password`.
- `--ssh-key PATH`: private key for `key` or `bootstrap-key`; its public key is
  `PATH.pub`.
- `--build-on auto|local|remote`: forwarded build placement, defaulting to
  `auto`.
- `--preflight`: execute every read-only validation and stop before key
  installation, confirmation, secret staging, or `nixos-anywhere`.
- `--help`: explain inputs, defaults, modes, destructive behavior, and example
  commands without evaluating the flake or connecting to a target.

Arguments are explicit so automation and tests do not depend on interactive
host selection. Gum is reserved for readable presentation and the mandatory
typed confirmation. There is no `--yes` or other confirmation bypass.

## Host and Disk Configuration

Add the Acerus device identity to `nix/constants.nix`:

```nix
hosts.acerus.systemDisk =
  "/dev/disk/by-id/nvme-eui.e8238fa6bf530001001b448b47e55428";
```

In `modules/hosts/acerus.nix`, override
`disko.devices.disk.btrfs.device` with that constant in the shared aspect, as
Esquire already does. The override therefore applies to both the daily and
installer profiles.

Remove the unsafe `/dev/nvme0n1` default from the shared Btrfs/LUKS layout.
The layout defines partitioning and filesystems; a physical host must supply
its disk identity. Evaluation must fail when a consumer does not provide a
device. Acerus and Esquire must both evaluate to `/dev/disk/by-id/...` paths.

Host resolution happens before SSH:

1. For `--host NAME`, prefer an existing `nixosConfigurations.NAME-installer`.
2. If the input already ends in `-installer`, require that exact output and
   derive the display host by removing the suffix.
3. Reject a missing output with the attempted configuration name and an
   actionable message.
4. Evaluate the selected configuration's system and top-level Disko disks.
5. Require exactly one top-level Disko disk and a device beginning with
   `/dev/disk/by-id/`.

The daily profile is never selected for destructive installation.

## Preflight Data Flow

Preflight is the common safety boundary used by both commands. It performs the
following operations in order:

1. Parse and validate all arguments without executing their values as shell
   syntax.
2. Resolve and evaluate the installer configuration before connecting to the
   target.
3. Extract the configuration system, single Disko device, default SOPS file,
   and per-secret SOPS-file overrides. Deduplicate the encrypted file paths.
4. Require a readable age identity. Run SOPS decryption for every required
   encrypted file with output directed to `/dev/null`. Print only the file
   identity and success or failure, never decrypted content or age material.
5. Validate local SSH key files when `key` or `bootstrap-key` mode is selected.
6. Verify SSH connectivity with the selected read-only authentication mode.
7. On the target, require the configured `/dev/disk/by-id/...` path to exist,
   resolve it with `readlink -f`, and query whole disks with
   `lsblk --json --bytes --nodeps --output PATH,TYPE,SIZE,MODEL,SERIAL`.
8. Require the resolved node to appear exactly once with type `disk`. A
   missing identifier, partition, device-mapper node, ambiguous result, or
   other mismatch is fatal.
9. Display the physical host, installer output, evaluated architecture, SSH
   target, build placement, configured identifier, resolved kernel path,
   size, model, and serial.

The `bootstrap-preflight` recipe stops here. It does not change target disk,
target SSH configuration, or local secret staging.

In `bootstrap-key` mode, standalone preflight uses password authentication to
perform remote inspection and validates that both local key files are ready.
It reports that installation will add the public key. During installation,
the app runs this password-authenticated preflight, installs the public key,
then repeats SSH connectivity and disk identity checks using only the new
private key. This preserves the existing bootstrap behavior without making a
nominally read-only preflight modify `authorized_keys`.

## Destructive Boundary and Installation

After preflight succeeds, installation displays the same disk record and asks
the operator to type this exact value:

```text
ERASE <physical-host> <configured-/dev/disk/by-id/path>
```

The application reads a fresh value with no prefilled default and compares it
byte-for-byte. Empty input, EOF, case changes, missing components, or any
other mismatch aborts before temporary staging or `nixos-anywhere`.

After confirmation:

1. Set a restrictive umask and create a private directory with `mktemp -d`.
2. Copy the age identity to both required extra-file paths:
   `/var/lib/sops-nix/keys.txt` and
   `/persist/var/lib/sops-nix/keys.txt`.
3. Force directory permissions to `0700` and file permissions to `0600`.
4. Install an EXIT/INT/TERM cleanup trap scoped to the exact temporary path.
5. Invoke the locked `nixos-anywhere` executable with the resolved
   `.#<host>-installer` flake, `--build-on`, `--extra-files`, SSH options, and
   the target host in the CLI form required by the pinned version.
6. Remove staged material on success, failure, or interruption.

The default `--build-on auto` allows nixos-anywhere to account for local and
target architecture. Operators may explicitly select `local` or `remote` for
live-installer constraints. The selected mode is shown in both preflight and
confirmation summaries.

## Error and Secret-Handling Contract

Every failure reports its stage, the non-secret value that failed validation,
and a concrete corrective action. Missing host output, missing or invalid
age identity, SOPS decryption failure, missing SSH key, unreachable SSH
target, missing stable disk symlink, disk mismatch, and failed confirmation
all exit nonzero before `nixos-anywhere` runs.

The implementation must not enable shell tracing. It must not print file
contents, SOPS output, private-key arguments, environment dumps, or temporary
directory contents. External commands that may include sensitive diagnostic
data have their output suppressed or reduced to a fixed error message. The
operator may see encrypted file paths and the SSH public-key path.

Explicit operator cancellation is reported as cancellation rather than a
successful installation. Cleanup is idempotent and never targets an
unresolved variable, repository directory, home directory, or filesystem
root.

## Automated Tests

Add a focused shell test under `tests/`. It builds a temporary `PATH` of
deterministic stubs for `nix`, `gum`, `ssh`, `ssh-copy-id`, `sops`, `lsblk`
where applicable, and `nixos-anywhere`. Command logs contain arguments and
synthetic non-secret fixtures only.

Cover at least:

- `--help` succeeds without Nix evaluation or SSH.
- `acerus` resolves to `acerus-installer`.
- An explicit `acerus-installer` resolves to the same configuration.
- Missing host output fails before SSH.
- A raw device path or multiple Disko disks fails before SSH.
- Missing age identity fails before SOPS or SSH.
- Failed SOPS decryption fails before SSH and prints no fixture secret.
- Unreachable SSH fails before remote disk inspection.
- A missing by-id path, partition result, or resolved-disk mismatch fails
  before confirmation.
- Successful preflight prints the evaluated configuration and disk metadata
  and never calls `nixos-anywhere` or `ssh-copy-id`.
- Incorrect typed confirmation never calls `nixos-anywhere`.
- `bootstrap-key` verifies the password inspection, public-key installation,
  and subsequent key-only inspection order.
- Successful installation forwards the installer flake, target, SSH options,
  and default `--build-on auto` exactly once.
- An explicit build-on override is forwarded unchanged.
- Both staged age-key paths exist with mode `0600` while the
  `nixos-anywhere` stub runs and are gone after exit.
- Failure and signal paths clean temporary staging.

Expose the test as a flake check so `nix flake check` exercises the packaged
script in addition to direct shell-test execution. Verification also includes
`nix run .#bootstrap -- --help`, `just --list`, formatting checks, and a search
proving that `--host-target` and unpinned nixos-anywhere/Disko invocations no
longer exist.

## Operator Documentation

Rewrite `docs/nixos-installer-bootstrap-ssh.md` around the supported app and
Just recipes. It must document:

- Live-installer prerequisites and password, key, and bootstrap-key modes.
- Preflight as the first operator command.
- How to correlate `lsblk` output with symlinks in `/dev/disk/by-id/` and add
  a host-specific `systemDisk` constant.
- The exact destructive confirmation and why a changed disk identity stops
  the workflow.
- Age-identity validation and the two temporary target paths without exposing
  secret material.
- Build placement overrides and common failure recovery.
- A separate new-host preparation step: collect a nixos-facter report, store
  it at the path expected by `define-hardware`, wire the aspect into the new
  host, and review the report before adding an installer profile. Bootstrap
  does not generate or commit hardware data automatically.

For both Acerus and Esquire, document this profile transition:

1. Install and boot the `*-installer` configuration using systemd-boot.
2. Verify networking, SSH access, persistent SOPS identity, storage mounts,
   and the retained LUKS recovery passphrase.
3. Enter UEFI Secure Boot Setup Mode before activating the daily profile.
4. Switch to the physical daily profile. The repository's Lanzaboote settings
   generate keys under the persistent `/etc/secureboot` bundle, prepare
   automatic enrollment, and reboot.
5. Verify Secure Boot state and signed artifacts with `sbctl status` before
   proceeding.
6. Enroll the LUKS device into TPM2 using PCR 7 only after Secure Boot is in
   its stable enabled state, while retaining the passphrase as recovery.
7. Re-enroll the TPM token after an intentional Secure Boot key or PCR-policy
   change.

The documentation must warn that automatic key enrollment requires firmware
Setup Mode and that firmware-specific recovery and vendor-key behavior must be
understood before clearing existing Platform Keys.

## Acceptance

The change is complete when:

- `nix run .#bootstrap -- --help` runs through the locked flake and documents
  every input and safety mode.
- `just --list` exposes only the supported physical bootstrap and preflight
  recipes for this workflow.
- Acerus and Esquire installer configurations evaluate to their stable EUI
  disk identifiers.
- Preflight is read-only and reports the installer configuration and physical
  disk identity.
- No destructive call can occur without the exact typed confirmation.
- Every specified early failure prevents a `nixos-anywhere` invocation and
  emits an actionable, non-secret diagnostic.
- Temporary age material exists only during the confirmed installation and is
  removed on every exit path.
- The focused stub suite, formatting checks, and `nix flake check` pass.
- Operator documentation covers new-host preparation and both physical hosts'
  installer-to-daily Secure Boot and TPM sequence.

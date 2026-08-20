# Bootstrap a Physical NixOS Machine over SSH

This runbook describes the physical-machine workflow implemented by
`scripts/nixos-installer.sh`, exposed by the `bootstrap` and
`bootstrap-preflight` Just recipes. It is deliberately separate from the VPS
profile and its provisioning workflow; do not use these disk-erasing steps for
`vps`.

## Safety Model

The workflow is designed for a NixOS live installer running on the target and a
source machine containing this checkout. It evaluates the selected installer
configuration, decrypts every effective SOPS file to `/dev/null`, and inspects
the configured whole disk over SSH before it can erase anything.

The disk must be the exact stable `/dev/disk/by-id/...` path declared by the
host. Kernel names such as `/dev/nvme0n1` can change when hardware enumeration
changes, so they are not accepted by the installer. The current physical host
identities are:

| Physical host | Installer profile | Stable whole-disk identity |
| --- | --- | --- |
| `acerus` | `acerus-installer` | `/dev/disk/by-id/nvme-eui.e8238fa6bf530001001b448b47e55428` |
| `esquire` | `esquire-installer` | `/dev/disk/by-id/nvme-eui.002538ba11b6cb55` |

Passing `--host acerus` or `--host esquire` selects the matching
`<host>-installer` configuration. Passing the explicit installer name is also
accepted, but the confirmation still names the physical host. The installer
profile uses systemd-boot; the daily profile uses Lanzaboote.

`bootstrap-preflight` is a read-only readiness check. It evaluates NixOS,
Disko, and SOPS, authenticates to SSH, resolves the stable symlink, and checks
that the target resolves to exactly one whole disk. It never invokes `gum`,
`ssh-copy-id`, or `nixos-anywhere`.

An installation always performs those same preflight checks before staging
secrets or invoking `nixos-anywhere`. It then requires the exact typed
confirmation shown in the summary. A wrong answer, EOF, or a failed preflight
stops without an installation. Treat the target disk as disposable: Disko and
`nixos-anywhere` will replace its partition table and contents.

## Live Installer Preparation

Boot the target into a NixOS live installer. All three modes require SSH to be
running. Password mode and `bootstrap-key` additionally require a temporary
root password; existing `key` mode requires the source private key to already
be authorized for the target account and does not require setting a password.
For password or `bootstrap-key`, set the temporary password, then start SSH
and record the address:

```bash
passwd
systemctl start sshd
systemctl status sshd
ip addr
```

The password is used only by password authentication and by the
`bootstrap-key` mode while the public key is installed. In existing `key`
mode, keep the authorized key and its private-key file available instead. Keep
the live installer's root SSH access available until preflight has completed.

## Source Machine Inputs

Run the workflow from the repository checkout. The source machine needs the
flake-native `nix` command, `just`, `jq`, `sops`, `gum`, and the packaged
`nixos-anywhere` input. The age identity defaults to
`$HOME/.local/share/ages/keys.txt`; pass `--age-identity PATH` when it is
stored elsewhere. The file is read locally and is never printed.

For key-based modes, keep the private key and its public companion together,
for example:

```text
~/.ssh_keys/id_ed25519
~/.ssh_keys/id_ed25519.pub
```

Before selecting a disk, collect the live installer's physical-disk inventory:

```bash
lsblk -d -o PATH,SIZE,MODEL,SERIAL
ls -l /dev/disk/by-id/
```

Use the whole-disk symlink, not a partition (`...-part1`) and not a mapper
device. Prefer an EUI or WWN identity under `/dev/disk/by-id/`, then compare
its resolved device, size, model, and serial with `lsblk` during preflight.

## Read-Only Preflight

Use a standalone preflight before an installation, especially after booting a
new live installer or changing the target address. The command below checks
Acerus without changing the target:

```bash
just bootstrap-preflight acerus root@192.0.2.10 \
  --age-identity "$HOME/.local/share/ages/keys.txt" \
  --ssh-auth password
```

Esquire uses the same workflow and its own installer profile and disk identity:

```bash
just bootstrap-preflight esquire root@192.0.2.11 \
  --age-identity "$HOME/.local/share/ages/keys.txt" \
  --ssh-auth password
```

The summary must show the expected installer configuration, target, stable
configured disk, resolved whole-disk path, size, model, serial, and
`Preflight : READY`. A standalone preflight stops there. It is not an
authorization to erase the disk; the install recipe repeats preflight and
requires a separate confirmation.

## Password Authentication

Password mode is the default and is useful when the live installer has a
temporary root password but no authorized key yet:

```bash
just bootstrap-preflight acerus root@192.0.2.10 \
  --ssh-auth password
```

After the preflight is reviewed, use the same options with `bootstrap`. The
script disables public-key authentication for its inspection and passes the
same password-only SSH policy to `nixos-anywhere`.

## Existing SSH-Key Authentication

Use this mode when the target already accepts the source private key. It never
uses a password or copies a key:

```bash
just bootstrap-preflight esquire root@192.0.2.11 \
  --ssh-auth key --ssh-key "$HOME/.ssh_keys/id_ed25519"

just bootstrap esquire root@192.0.2.11 \
  --ssh-auth key --ssh-key "$HOME/.ssh_keys/id_ed25519" \
  --age-identity "$HOME/.local/share/ages/keys.txt" \
  --build-on auto
```

The private key is required locally and is used with public-key-only SSH.

## Bootstrap a New SSH Key

Use `bootstrap-key` when the live installer permits the temporary root
password but does not yet contain the desired public key:

```bash
just bootstrap-preflight acerus root@192.0.2.10 \
  --ssh-auth bootstrap-key --ssh-key "$HOME/.ssh_keys/id_ed25519"
```

The standalone preflight only checks the disk using password authentication.
For an installation, the script first runs that password inspection, then
uses `ssh-copy-id` with the public key, switches to public-key-only SSH, and
inspects the disk again before confirmation. The private key is then passed to
`nixos-anywhere`; the temporary password is not used after key installation.

## Confirm and Install

Run the installation only after a successful preflight and a reviewed target
inventory. For example:

```bash
just bootstrap acerus root@192.0.2.10 \
  --ssh-auth bootstrap-key --ssh-key "$HOME/.ssh_keys/id_ed25519" \
  --age-identity "$HOME/.local/share/ages/keys.txt" \
  --build-on auto
```

The equivalent Esquire installation uses `esquire` and its target address:

```bash
just bootstrap esquire root@192.0.2.11 \
  --ssh-auth key --ssh-key "$HOME/.ssh_keys/id_ed25519" \
  --age-identity "$HOME/.local/share/ages/keys.txt" \
  --build-on auto
```

The prompt is intentionally exact. For Acerus, type:

```text
ERASE acerus /dev/disk/by-id/nvme-eui.e8238fa6bf530001001b448b47e55428
```

For Esquire, type:

```text
ERASE esquire /dev/disk/by-id/nvme-eui.002538ba11b6cb55
```

The host and disk must match the summary character-for-character. The
`--build-on` value (`auto`, `local`, or `remote`) is forwarded to
`nixos-anywhere`.

Before installation, the age identity is staged with mode `0600` at both
paths expected by the NixOS configuration:

```text
/var/lib/sops-nix/keys.txt
/persist/var/lib/sops-nix/keys.txt
```

The paths are supplied as extra files to the installer and the temporary
staging directory is removed on success, failure, or interruption. Do not put
secret contents in shell arguments or this runbook.

## Add a New Physical Host

Keep a new physical host separate from a VPS host. Before adding configuration,
boot its live installer and record the inventory:

1. Run `lsblk -d -o PATH,SIZE,MODEL,SERIAL` and retain the output for review.
2. Inspect `/dev/disk/by-id/` for symlinks to the intended whole disk. Prefer
   an EUI/WWN identity and never select a partition or `/dev/nvme0n1` merely
   because it is the current kernel name.
3. Add `constants.hosts.<name>.systemDisk` in `nix/constants.nix` with the
   exact `/dev/disk/by-id/...` path, and add a host-level
   `lib.mkForce constants.hosts.<name>.systemDisk` override in
   `modules/hosts/<name>.nix`.
4. Generate a nixos-facter report separately on the new machine, review it,
   and store it at `modules/hosts/<name>/facter.json`, for example:

   ```bash
   nixos-facter -o modules/hosts/<name>/facter.json
   ```

   This is the path used by `<lib/define-hardware>` (`modules/lib.nix`). If
   this host should consume the report, include `<lib/define-hardware>` in its
   host aspect deliberately; do not assume a missing report is acceptable.
5. Define both `<name>` and `<name>-installer` host profiles before running
   preflight. The daily profile should use Lanzaboote; the installer profile
   should use systemd-boot until the first daily transition is complete.

Review the generated facter report and the Disko path as separate changes. A
facter report describes hardware; it does not choose the install disk.

## First Boot Checks

After `nixos-anywhere` returns, boot the installed installer profile and verify
the machine has the expected host name, network, encrypted root, and persisted
state before changing profiles. Confirm that the SOPS key and secrets are
available through the staged paths and that `/persist` is mounted. Keep the
LUKS passphrase available while validating the new system.

## Switch Acerus or Esquire to the Daily Profile

The installer's `acerus-installer` and `esquire-installer` profiles use
systemd-boot. Once the first boot is healthy, switch to the matching daily
profile from the checkout:

```bash
# On an Acerus installed with acerus-installer:
nh os switch . -H acerus

# On an Esquire installed with esquire-installer:
nh os switch . -H esquire
```

The daily profiles use Lanzaboote. `/etc/secureboot` is persisted by the
impermanence configuration, so the generated Secure Boot material survives
the root rollback. Firmware must be in Secure Boot Setup Mode before the daily
activation: use the firmware UI to disable Secure Boot and clear or reset
platform keys as required by that machine. This is a firmware operation, not a
Disko operation.

Lanzaboote is configured here to generate keys automatically, prepare
automatic enrollment, and allow an automatic reboot. The reboot can occur
during the switch; return to the machine and complete the checks below before
enrolling the TPM.

## Secure Boot Enrollment

After the daily profile has booted, check the boot state and enrollment:

```bash
sudo sbctl status
```

The status must show the expected Secure Boot state and a valid Lanzaboote
setup. Do not enroll a TPM token until `sbctl status` passes. If enrollment
cannot complete, return firmware to Setup Mode and inspect the firmware's
platform/key-exchange databases before retrying the daily switch. Keep
`/etc/secureboot` backed by `/persist` and do not delete it during recovery.

## TPM2 Enrollment

Once Secure Boot is enrolled and `sbctl status` passes, enroll the LUKS root
volume against TPM PCR 7. Disko names the `root` partition under the `btrfs`
disk, so its generated partition label is `disk-btrfs-root`:

```bash
sudo systemd-cryptenroll \
  --tpm2-device=auto \
  --tpm2-pcrs=7 \
  /dev/disk/by-partlabel/disk-btrfs-root
```

The LUKS passphrase remains a recovery method and should be tested before
removing any other recovery material. PCR 7 binds the TPM unlock policy to the
Secure Boot state. An intentional Secure Boot key change, boot-policy change,
firmware reset, or other PCR 7/key-policy change requires re-enrollment with
`systemd-cryptenroll`; retain the passphrase until the new token is confirmed.

## Failure Recovery

- If preflight fails, correct the host mapping, SOPS identity, SSH access, or
  stable disk configuration and rerun it. No destructive helper is run before
  preflight succeeds.
- If SSH password bootstrap fails, check `sshd`, the temporary root password,
  root login policy, and the target address in the live installer.
- If `bootstrap-key` fails during `ssh-copy-id`, the public key was not
  accepted; fix password access and rerun. The installer does not proceed to
  `nixos-anywhere` in that case.
- If installation is interrupted, the staged age-key directory is cleaned up;
  verify the target's state from the live installer before retrying.
- If the daily Lanzaboote transition cannot enroll keys, leave firmware in
  Setup Mode, preserve `/etc/secureboot` and `/persist`, and boot the installer
  or a known-good entry while investigating. Do not erase the target again
  merely to repair Secure Boot.
- If TPM PCR 7 unlock stops working after an intentional Secure Boot or
  firmware change, unlock with the LUKS passphrase, verify `sbctl status`, and
  re-enroll the TPM token. The passphrase is the recovery path.

# NDD-95 NixOS Anywhere Bootstrap Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build one pinned SSH bootstrap command that validates the selected physical host, SOPS identity, remote disk, and explicit destructive confirmation before invoking `nixos-anywhere`.

**Architecture:** A packaged Bash orchestrator is the workflow boundary. Its preflight functions serve both the standalone read-only command and the mandatory first phase of installation; Nix evaluation supplies the installer configuration, Disko device, and SOPS files, while SSH supplies target disk identity. Stubbed tests enforce ordering and prove every failure occurs before `nixos-anywhere`.

**Tech Stack:** Nix Flakes, flake-parts/import-tree, vic/flake-file, Bash, nixos-anywhere, Disko, OpenSSH, SOPS/age, jq, Gum, Just, and shell command stubs.

**Spec:** `docs/superpowers/specs/2026-08-20-ndd-95-nixos-anywhere-bootstrap-design.md`

## Global Constraints

- Edit generated flake declarations in `nix/dendritic.nix`; regenerate `flake.nix` rather than editing it directly.
- Pin `nixos-anywhere` through `flake.lock`; no runtime `github:` invocation is allowed.
- Use modern flake-first Nix commands only, and keep VPS provisioning outside this work.
- Require exactly one Disko disk using `/dev/disk/by-id/...`.
- Default `--build-on` to `auto`; accept only `auto`, `local`, or `remote`.
- Never print age identity, decrypted SOPS values, private SSH keys, or staged contents.
- Never call `nixos-anywhere` before remote disk validation and exact typed confirmation.
- Preflight must not mutate disk, SSH configuration, or local secret staging.
- Stage both required age-key paths only after confirmation, using `0700` directories and `0600` files.
- Use focused local Git commits; never push, fetch, pull, or otherwise contact upstream.
- Preserve cross-platform evaluation and expose the package only where the pinned nixos-anywhere input supplies it.

## File Responsibilities

- `nix/constants.nix`: stable physical-disk identities.
- `modules/hosts/acerus.nix`: Acerus Disko override shared by installer and daily profiles.
- `modules/disko/btrfs-luks.nix`: encrypted layout without a raw device default.
- `nix/checks/bootstrap-config.nix`: stable-disk evaluation assertions.
- `nix/dendritic.nix`, generated `flake.nix`, and `flake.lock`: pinned input.
- `nix/bootstrap.nix`: bootstrap package, app, and shell-test check.
- `scripts/nixos-installer.sh`: complete orchestration logic.
- `tests/nixos-installer.sh`: stubs and behavioral assertions.
- `justfile`: supported bootstrap command surface.
- `docs/nixos-installer-bootstrap-ssh.md` and `README.md`: operator-facing workflow.

---

### Task 1: Require Stable Physical Disk Identities

**Files:**
- Modify: `nix/constants.nix`
- Modify: `modules/hosts/acerus.nix`
- Modify: `modules/disko/btrfs-luks.nix`
- Create: `nix/checks/bootstrap-config.nix`

**Interfaces:**
- Consumes: existing Esquire disk constant and `disko.devices.disk.btrfs`.
- Produces: `constants.hosts.acerus.systemDisk` and `checks.bootstrap-disk-config`.

- [ ] **Step 1: Write the failing disk-identity check**

Create `nix/checks/bootstrap-config.nix`:

```nix
{ constants, lib, self, ... }:
{
  perSystem =
    { pkgs, ... }:
    let
      diskFor = host: self.nixosConfigurations.${host}.config.disko.devices.disk.btrfs.device;
      acerusDisk = diskFor "acerus-installer";
      esquireDisk = diskFor "esquire-installer";
    in
    {
      checks.bootstrap-disk-config =
        assert acerusDisk == "/dev/disk/by-id/nvme-eui.e8238fa6bf530001001b448b47e55428";
        assert esquireDisk == constants.hosts.esquire.systemDisk;
        assert lib.hasPrefix "/dev/disk/by-id/" acerusDisk;
        assert lib.hasPrefix "/dev/disk/by-id/" esquireDisk;
        pkgs.runCommand "bootstrap-disk-config" { } ''
          touch "$out"
        '';
    };
}
```

- [ ] **Step 2: Verify the new check fails**

Run:

```bash
nix build path:.#checks.$(nix eval --raw --impure --expr builtins.currentSystem).bootstrap-disk-config
```

Expected: FAIL because Acerus still evaluates to `/dev/nvme0n1`.

- [ ] **Step 3: Add Acerus identity and override**

Change `nix/constants.nix` to:

```nix
hosts = {
  acerus.systemDisk = "/dev/disk/by-id/nvme-eui.e8238fa6bf530001001b448b47e55428";
  esquire.systemDisk = "/dev/disk/by-id/nvme-eui.002538ba11b6cb55";
};
```

Inside `mkAcerusAspect` add:

```nix
disko.devices.disk.btrfs.device = lib.mkForce constants.hosts.acerus.systemDisk;
```

Remove `device = lib.mkDefault "/dev/nvme0n1";`, `inherit device;`, and the now-unused `lib`/`constants` function arguments from `modules/disko/btrfs-luks.nix`. The layout no longer supplies a fallback disk.

- [ ] **Step 4: Verify both installer devices**

Run:

```bash
nix build path:.#checks.$(nix eval --raw --impure --expr builtins.currentSystem).bootstrap-disk-config
nix eval --raw path:.#nixosConfigurations.acerus-installer.config.disko.devices.disk.btrfs.device
nix eval --raw path:.#nixosConfigurations.esquire-installer.config.disko.devices.disk.btrfs.device
```

Expected: PASS; the evals print the exact Acerus and Esquire EUI paths.

- [ ] **Step 5: Commit**

```bash
git add nix/constants.nix \
  modules/hosts/acerus.nix \
  modules/disko/btrfs-luks.nix \
  nix/checks/bootstrap-config.nix
git commit -m "fix(bootstrap): require stable physical disk identities"
```

---

### Task 2: Pin and Package the Bootstrap Help Surface

**Files:**
- Modify: `nix/dendritic.nix`
- Regenerate: `flake.nix`
- Modify: `flake.lock`
- Create: `nix/bootstrap.nix`
- Rewrite: `scripts/nixos-installer.sh`
- Create: `tests/nixos-installer.sh`

**Interfaces:**
- Consumes: `inputs'.nixos-anywhere.packages.nixos-anywhere`.
- Produces: `packages.bootstrap`, `apps.bootstrap`, and a Bash CLI with deterministic `--help`.

- [ ] **Step 1: Write the failing help test**

Create `tests/nixos-installer.sh`:

```bash
#!/usr/bin/env bash
set -euo pipefail

script=${1:-"$(cd -- "$(dirname -- "$0")/.." && pwd)/scripts/nixos-installer.sh"}
repo_root=${2:-"$(cd -- "$(dirname -- "$script")/.." && pwd)"}
test_root=$(mktemp -d)
trap 'rm -rf -- "$test_root"' EXIT INT TERM

fail() { printf 'FAIL: %s\n' "$*" >&2; exit 1; }
assert_contains() {
  local haystack=$1 needle=$2
  [[ $haystack == *"$needle"* ]] || fail "missing output: $needle"
}

help_output=$(bash "$script" --help)
for expected in '--host HOST' '--target USER@ADDRESS' '--age-identity PATH' \
  '--ssh-auth password|key|bootstrap-key' '--ssh-key PATH' \
  '--build-on auto|local|remote' '--preflight' 'ERASE'; do
  assert_contains "$help_output" "$expected"
done
printf 'nixos-installer tests passed\n'
```

- [ ] **Step 2: Verify the old Zsh script fails**

Run `bash tests/nixos-installer.sh scripts/nixos-installer.sh .`.

Expected: FAIL because the existing script requires Gum immediately and has no help contract.

- [ ] **Step 3: Replace the Zsh entry with a Bash parser**

Start `scripts/nixos-installer.sh` with `#!/usr/bin/env bash` and `set -euo pipefail`. Implement this option loop:

```bash
host=
target=
age_identity=${HOME:+$HOME/.local/share/ages/keys.txt}
ssh_auth=password
ssh_key=
build_on=auto
preflight=false

while (($#)); do
  case $1 in
    --host|--target|--age-identity|--ssh-auth|--ssh-key|--build-on)
      (($# >= 2)) || { printf 'Error [arguments]: %s requires a value.\n' "$1" >&2; exit 2; }
      option=$1; value=$2; shift 2
      case $option in
        --host) host=$value ;;
        --target) target=$value ;;
        --age-identity) age_identity=$value ;;
        --ssh-auth) ssh_auth=$value ;;
        --ssh-key) ssh_key=$value ;;
        --build-on) build_on=$value ;;
      esac
      ;;
    --preflight) preflight=true; shift ;;
    --help|-h) usage; exit 0 ;;
    *) printf 'Error [arguments]: unknown option: %s\n' "$1" >&2; usage >&2; exit 2 ;;
  esac
done
```

The `usage` heredoc must include every string asserted by Step 1, examples for `nix run` and Just, defaults, and the exact `ERASE <host> <disk>` rule. Remove Zsh `print`, interactive host selection, and GitHub fallback logic.

- [ ] **Step 4: Verify parser syntax and help**

Run:

```bash
bash -n scripts/nixos-installer.sh
bash tests/nixos-installer.sh scripts/nixos-installer.sh .
```

Expected: PASS.

- [ ] **Step 5: Add and lock the input**

Add to `flake-file.inputs` in `nix/dendritic.nix`:

```nix
nixos-anywhere = {
  url = "github:nix-community/nixos-anywhere";
  inputs.nixpkgs.follows = "nixpkgs";
};
```

Run:

```bash
nix run path:.#write-flake
nix flake update nixos-anywhere
```

Expected: generated `flake.nix` and the root lock inputs contain `nixos-anywhere`; no unrelated input is intentionally updated.

- [ ] **Step 6: Expose package and app**

Create `nix/bootstrap.nix`:

```nix
{ lib, ... }:
{
  perSystem =
    { inputs', pkgs, ... }:
    lib.optionalAttrs (inputs'.nixos-anywhere.packages ? nixos-anywhere) (
      let
        bootstrap = pkgs.writeShellApplication {
          name = "bootstrap";
          runtimeInputs = [
            pkgs.coreutils
            pkgs.gum
            pkgs.jq
            pkgs.nix
            pkgs.openssh
            pkgs.sops
            inputs'.nixos-anywhere.packages.nixos-anywhere
          ];
          text = builtins.readFile ../scripts/nixos-installer.sh;
        };
      in
      {
        packages.bootstrap = bootstrap;
        apps.bootstrap = { type = "app"; program = lib.getExe bootstrap; };
      }
    );
}
```

- [ ] **Step 7: Verify and commit**

Run `nix run path:.#bootstrap -- --help`; expect exit 0 without SSH. Then commit:

```bash
git add nix/dendritic.nix flake.nix flake.lock \
  nix/bootstrap.nix scripts/nixos-installer.sh tests/nixos-installer.sh
git commit -m "feat(bootstrap): package pinned nixos-anywhere entry point"
```

---

### Task 3: Validate Host Configuration and SOPS Inputs Locally

**Files:**
- Modify: `scripts/nixos-installer.sh`
- Modify: `tests/nixos-installer.sh`
- Modify: `nix/bootstrap.nix`

**Interfaces:**
- Consumes: parsed CLI values and `nixosConfigurations.<host>-installer`.
- Produces: `physical_host`, `installer_host`, `host_system`, `disko_device`, `sops_files`; functions `validate_arguments`, `resolve_configuration`, and `validate_sops`.

- [ ] **Step 1: Add isolated stub helpers**

Add before the help test:

```bash
original_path=$PATH

new_case() {
  case_dir=$test_root/case-$RANDOM
  stub_dir=$case_dir/bin
  log_dir=$case_dir/log
  mkdir -p "$stub_dir" "$log_dir"
  export BOOTSTRAP_TEST_LOG=$log_dir
  export PATH=$stub_dir:$original_path
  age_file=$case_dir/keys.txt
  printf 'AGE-SECRET-KEY-1TESTFIXTURE\n' >"$age_file"
  chmod 600 "$age_file"
}

write_stub() {
  local name=$1; shift
  { printf '%s\n' '#!/usr/bin/env bash' 'set -euo pipefail'; printf '%s\n' "$@"; } >"$stub_dir/$name"
  chmod +x "$stub_dir/$name"
}

run_capture() {
  set +e
  output=$(bash "$script" "$@" 2>&1)
  status=$?
  set -e
}

assert_status() {
  [[ $status == "$1" ]] || fail "expected status $1, got $status: $output"
}
```

Use only synthetic encrypted paths and identities.

- [ ] **Step 2: Add failing local-validation cases**

Use a `nix` stub that logs arguments and returns:

```bash
case "$*" in
  *acerus-installer.config.nixpkgs.hostPlatform.system*) printf 'x86_64-linux' ;;
  *acerus-installer.config.disko.devices.disk*)
    printf '%s\n' '{"btrfs":{"device":"/dev/disk/by-id/nvme-eui.e8238fa6bf530001001b448b47e55428"}}'
    ;;
  *acerus-installer.config.sops*)
    printf '%s\n' '["/nix/store/test-acerus-secrets.yaml","/nix/store/test-shared-secrets.yaml"]'
    ;;
  *) exit 1 ;;
esac
```

Add fresh cases for:

- `acerus` and explicit `acerus-installer` normalizing to the same output.
- Missing host output failing before SOPS or SSH.
- `/dev/nvme0n1` failing before SOPS or SSH.
- Two top-level Disko disks failing before SOPS or SSH.
- Missing age identity failing before SOPS or SSH.
- SOPS stub exit 1 failing before SSH and never printing `AGE-SECRET-KEY-1TESTFIXTURE`.

Example assertion:

```bash
run_capture --host missing --target root@192.0.2.10 --age-identity "$age_file" --preflight
assert_status 1
assert_contains "$output" 'Error [configuration]'
[[ ! -e $log_dir/ssh ]] || fail 'SSH ran for a missing host'
```

- [ ] **Step 3: Verify tests fail before implementation**

Run `bash tests/nixos-installer.sh scripts/nixos-installer.sh .`.

Expected: FAIL on the first preflight case because the script only parses arguments.

- [ ] **Step 4: Implement strict argument validation**

Add:

```bash
die() { local stage=$1; shift; printf 'Error [%s]: %s\n' "$stage" "$*" >&2; exit 1; }

validate_arguments() {
  [[ -n $host ]] || die arguments '--host is required.'
  [[ -n $target ]] || die arguments '--target is required.'
  [[ $host =~ ^[A-Za-z0-9][A-Za-z0-9._-]*$ ]] || die arguments '--host contains unsupported characters.'
  [[ $target == *@* && $target != *[[:space:]]* ]] || die arguments '--target must be USER@ADDRESS without whitespace.'
  case $ssh_auth in password|key|bootstrap-key) ;; *) die arguments '--ssh-auth must be password, key, or bootstrap-key.' ;; esac
  case $build_on in auto|local|remote) ;; *) die arguments '--build-on must be auto, local, or remote.' ;; esac
  if [[ $ssh_auth == key || $ssh_auth == bootstrap-key ]]; then
    [[ -n $ssh_key ]] || die arguments '--ssh-key is required for key authentication.'
    [[ -r $ssh_key ]] || die ssh "private key is not readable: $ssh_key"
    [[ -r $ssh_key.pub ]] || die ssh "public key is not readable: $ssh_key.pub"
  fi
}
```

- [ ] **Step 5: Resolve the installer and single stable disk**

Set `BOOTSTRAP_FLAKE_SOURCE=${BOOTSTRAP_FLAKE_SOURCE:-.}` and implement:

```bash
resolve_configuration() {
  physical_host=${host%-installer}
  if [[ $host == *-installer ]]; then installer_host=$host; else installer_host=$host-installer; fi
  local attr="$BOOTSTRAP_FLAKE_SOURCE#nixosConfigurations.$installer_host.config"
  host_system=$(nix eval --raw "$attr.nixpkgs.hostPlatform.system" 2>/dev/null) ||
    die configuration "missing nixosConfigurations.$installer_host; add an installer profile first."
  local disks_json disk_count
  disks_json=$(nix eval --json "$attr.disko.devices.disk" 2>/dev/null) ||
    die configuration "cannot evaluate Disko disks for $installer_host."
  disk_count=$(jq 'length' <<<"$disks_json")
  [[ $disk_count == 1 ]] || die configuration "$installer_host must define exactly one Disko disk; found $disk_count."
  disko_device=$(jq -er 'to_entries[0].value.device | select(type == "string")' <<<"$disks_json") ||
    die configuration "$installer_host does not define a Disko device."
  [[ $disko_device == /dev/disk/by-id/* ]] ||
    die configuration "Disko device must use /dev/disk/by-id/: $disko_device"
}
```

- [ ] **Step 6: Verify every effective SOPS file without output**

Implement:

```bash
validate_sops() {
  [[ -r $age_identity ]] || die secrets "age identity is not readable: $age_identity"
  local attr="$BOOTSTRAP_FLAKE_SOURCE#nixosConfigurations.$installer_host.config.sops"
  local files_json encrypted_file
  files_json=$(nix eval --json "$attr" --apply \
    'sops: builtins.map (secret: toString secret.sopsFile) (builtins.attrValues sops.secrets)' \
    2>/dev/null) || die secrets "cannot evaluate SOPS files for $installer_host."
  mapfile -t sops_files < <(jq -er 'unique[]' <<<"$files_json")
  ((${#sops_files[@]} > 0)) || die secrets "$installer_host has no required SOPS files."
  for encrypted_file in "${sops_files[@]}"; do
    SOPS_AGE_KEY_FILE=$age_identity sops decrypt --output /dev/null "$encrypted_file" >/dev/null 2>&1 ||
      die secrets "cannot decrypt required SOPS file: $encrypted_file"
    printf 'SOPS               : OK (%s)\n' "$encrypted_file"
  done
}
```

Call validation, resolution, and SOPS verification in that order.

- [ ] **Step 7: Pass source tests and add the flake check**

Add inside the supported-system attrset in `nix/bootstrap.nix`:

```nix
checks.bootstrap-shell = pkgs.runCommand "bootstrap-shell-tests" {
  nativeBuildInputs = [ pkgs.bash pkgs.coreutils ];
} ''
  bash ${../tests/nixos-installer.sh} ${../scripts/nixos-installer.sh} ${../.}
  touch "$out"
'';
```

Run:

```bash
bash -n scripts/nixos-installer.sh
bash tests/nixos-installer.sh scripts/nixos-installer.sh .
nix build path:.#checks.$(nix eval --raw --impure --expr builtins.currentSystem).bootstrap-shell
```

Expected: all local cases pass.

- [ ] **Step 8: Commit**

```bash
git add scripts/nixos-installer.sh tests/nixos-installer.sh nix/bootstrap.nix
git commit -m "feat(bootstrap): validate host and encrypted inputs"
```

---

### Task 4: Inspect and Match the Remote Disk over SSH

**Files:**
- Modify: `scripts/nixos-installer.sh`
- Modify: `tests/nixos-installer.sh`

**Interfaces:**
- Consumes: validated configuration and CLI values from Task 3.
- Produces: `ssh_command`, `nixos_anywhere_ssh_options`, resolved disk metadata, and functions `configure_ssh`, `inspect_remote_disk`, `print_summary`.

- [ ] **Step 1: Add failing remote cases**

Stub SOPS to succeed. Add SSH fixtures for:

```json
{"blockdevices":[{"path":"/dev/nvme0n1p1","type":"part","size":1073741824,"model":"WD PC SN740","serial":"240960811264"}]}
```

and:

```json
{"blockdevices":[{"path":"/dev/nvme0n1","type":"disk","size":1024209543168,"model":"WD PC SN740 SDDQNQD-1T00-1014","serial":"240960811264"}]}
```

Also cover SSH exit 255 and missing-device exit 4. Assert unreachable SSH reports `Error [ssh]`; missing/partition results report `Error [disk]`; and none invokes Gum, `ssh-copy-id`, or `nixos-anywhere`.

- [ ] **Step 2: Add the failing READY report assertion**

For the valid disk and `--preflight`, require:

```text
Host               : acerus
Configuration      : acerus-installer
Architecture       : x86_64-linux
Target             : root@192.0.2.10
Build on           : auto
Configured disk    : /dev/disk/by-id/nvme-eui.e8238fa6bf530001001b448b47e55428
Resolved disk      : /dev/nvme0n1
Model              : WD PC SN740 SDDQNQD-1T00-1014
Serial             : 240960811264
Preflight          : READY
```

- [ ] **Step 3: Verify remote tests fail**

Run `bash tests/nixos-installer.sh scripts/nixos-installer.sh .`.

Expected: FAIL because SSH inspection is absent.

- [ ] **Step 4: Construct SSH options once**

Implement:

```bash
configure_ssh() {
  ssh_command=(ssh -o ConnectTimeout=10)
  nixos_anywhere_ssh_options=()
  case $ssh_auth in
    password|bootstrap-key)
      ssh_command+=(-o PreferredAuthentications=password -o PubkeyAuthentication=no)
      nixos_anywhere_ssh_options+=(--ssh-option PreferredAuthentications=password --ssh-option PubkeyAuthentication=no)
      ;;
    key)
      ssh_command+=(-o PreferredAuthentications=publickey -o PasswordAuthentication=no -o IdentitiesOnly=yes -i "$ssh_key")
      nixos_anywhere_ssh_options+=(--ssh-option PreferredAuthentications=publickey --ssh-option PasswordAuthentication=no --ssh-option IdentitiesOnly=yes --ssh-option "IdentityFile=$ssh_key")
      ;;
  esac
}
```

- [ ] **Step 5: Inspect the configured device using a fixed remote program**

Execute `ssh ... "$target" bash -s -- "$disko_device"` with this literal stdin:

```bash
set -euo pipefail
configured_disk=$1
[[ -e $configured_disk ]] || exit 4
resolved=$(readlink -f -- "$configured_disk") || exit 4
lsblk --json --bytes --nodeps --output PATH,TYPE,SIZE,MODEL,SERIAL "$resolved"
```

Capture status before using `die`: status 4 means `Error [disk]: configured device is missing`; all other nonzero statuses mean `Error [ssh]`. Use jq to require exactly one `.blockdevices` entry whose type is `disk`, then extract path, numeric size, model defaulting to `unknown`, and serial defaulting to `unknown`.

- [ ] **Step 6: Print the summary and stop standalone preflight**

Implement fixed-label `print_summary` matching Step 2. After remote inspection:

```bash
print_summary
if $preflight; then
  printf 'Preflight          : READY\n'
  exit 0
fi
```

- [ ] **Step 7: Verify and commit**

Run syntax and the full source suite; expect all remote failure and READY cases to pass with no destructive call. Commit:

```bash
git add scripts/nixos-installer.sh tests/nixos-installer.sh
git commit -m "feat(bootstrap): verify remote disk before install"
```

---

### Task 5: Gate Installation and Stage Secrets Securely

**Files:**
- Modify: `scripts/nixos-installer.sh`
- Modify: `tests/nixos-installer.sh`

**Interfaces:**
- Consumes: validated preflight state and SSH arrays from Task 4.
- Produces: `bootstrap_ssh_key`, `confirm_destruction`, `stage_age_identity`, `cleanup`, and `run_install`; one confirmed installer invocation.

- [ ] **Step 1: Add failing confirmation cases**

Stub `gum input` with `NO`, EOF/exit 1, a value with the wrong host, and this success value:

```text
ERASE acerus /dev/disk/by-id/nvme-eui.e8238fa6bf530001001b448b47e55428
```

Every mismatch must exit nonzero, print `Installation cancelled`, and leave no `nixos-anywhere` log.

- [ ] **Step 2: Add failing staging and forwarding cases**

Make the `nixos-anywhere` stub record one argument per line, find the argument after `--extra-files`, and assert during execution:

```bash
test -f "$extra_files/var/lib/sops-nix/keys.txt"
test -f "$extra_files/persist/var/lib/sops-nix/keys.txt"
test "$(stat -c %a "$extra_files/var/lib/sops-nix/keys.txt")" = 600
test "$(stat -c %a "$extra_files/persist/var/lib/sops-nix/keys.txt")" = 600
```

Require the argument log to contain the following ordered values:

```text
--flake
.#acerus-installer
--build-on
auto
--extra-files
root@192.0.2.10
```

Record the staging root and assert it disappears after success and after installer exit 23. Add a `--build-on local` case and require `local` instead of `auto`.

- [ ] **Step 3: Add failing bootstrap-key ordering cases**

Create synthetic `id_ed25519` and `id_ed25519.pub`. For `--ssh-auth bootstrap-key`, require this log order:

1. Password-only SSH disk inspection.
2. `ssh-copy-id` using the public key.
3. Public-key-only SSH disk inspection.
4. Gum typed confirmation.
5. `nixos-anywhere` with `IdentityFile=<private-path>` and password authentication disabled.

Standalone `--preflight` must perform only step 1 and never call `ssh-copy-id`.

- [ ] **Step 4: Verify installation tests fail**

Run `bash tests/nixos-installer.sh scripts/nixos-installer.sh .`.

Expected: FAIL because installation stops after preflight.

- [ ] **Step 5: Bootstrap and revalidate the SSH key**

Implement:

```bash
bootstrap_ssh_key() {
  [[ $ssh_auth == bootstrap-key ]] || return 0
  ssh-copy-id -i "$ssh_key.pub" \
    -o PreferredAuthentications=password \
    -o PubkeyAuthentication=no \
    "$target" >/dev/null || die ssh "could not install public key on $target."
  ssh_auth=key
  configure_ssh
  inspect_remote_disk
}
```

Call it after the password preflight report and before confirmation. Print only the public-key path in its success message.

- [ ] **Step 6: Implement exact confirmation**

```bash
confirm_destruction() {
  local expected reply
  expected="ERASE $physical_host $disko_device"
  printf 'Type exactly: %s\n' "$expected"
  reply=$(gum input --prompt '> ') || {
    printf 'Installation cancelled: no confirmation received.\n' >&2
    exit 1
  }
  if [[ $reply != "$expected" ]]; then
    printf 'Installation cancelled: confirmation did not match.\n' >&2
    exit 1
  fi
}
```

Do not add an environment or flag bypass, default input, or case-insensitive comparison.

- [ ] **Step 7: Implement guarded staging and cleanup**

```bash
staging_root=

cleanup() {
  local candidate=${staging_root:-}
  local temp_parent=${TMPDIR:-/tmp}
  [[ -n $candidate && $candidate == "$temp_parent"/nixos-bootstrap.* ]] || return 0
  [[ $candidate != "$temp_parent" && $candidate != /tmp && -d $candidate ]] || return 0
  rm -rf -- "$candidate"
  staging_root=
}

stage_age_identity() {
  umask 077
  staging_root=$(mktemp -d "${TMPDIR:-/tmp}/nixos-bootstrap.XXXXXXXX") ||
    die staging 'could not create a temporary directory.'
  trap cleanup EXIT INT TERM
  install -d -m 0700 "$staging_root/var/lib/sops-nix" "$staging_root/persist/var/lib/sops-nix"
  install -m 0600 "$age_identity" "$staging_root/var/lib/sops-nix/keys.txt"
  install -m 0600 "$age_identity" "$staging_root/persist/var/lib/sops-nix/keys.txt"
}
```

Tests set `TMPDIR=$case_dir/tmp`, verify both successful and failing cleanup, and verify the parent remains.

- [ ] **Step 8: Invoke the locked executable**

```bash
run_install() {
  nixos-anywhere \
    --flake "$BOOTSTRAP_FLAKE_SOURCE#$installer_host" \
    --build-on "$build_on" \
    --extra-files "$staging_root" \
    "${nixos_anywhere_ssh_options[@]}" \
    "$target"
}

bootstrap_ssh_key
confirm_destruction
stage_age_identity
run_install
printf 'Installation command completed for %s.\n' "$physical_host"
```

Never probe for an alternate executable or call `nix run` from the script.

- [ ] **Step 9: Verify source and packaged checks**

Run:

```bash
bash -n scripts/nixos-installer.sh
bash tests/nixos-installer.sh scripts/nixos-installer.sh .
nix build path:.#checks.$(nix eval --raw --impure --expr builtins.currentSystem).bootstrap-shell
nix run path:.#bootstrap -- --help
```

Expected: PASS; failure cases invoke no installer and leak no fixture secret.

- [ ] **Step 10: Commit**

```bash
git add scripts/nixos-installer.sh tests/nixos-installer.sh
git commit -m "feat(bootstrap): gate remote install and secret staging"
```

---

### Task 6: Consolidate the Just Command Surface

**Files:**
- Modify: `justfile`
- Modify: `tests/nixos-installer.sh`
- Modify: `nix/bootstrap.nix`

**Interfaces:**
- Consumes: `apps.bootstrap` and its CLI.
- Produces: only `bootstrap` and `bootstrap-preflight` as supported physical bootstrap recipes.

- [ ] **Step 1: Add a failing command-surface test**

Append:

```bash
justfile=$repo_root/justfile
just_list=$(just --justfile "$justfile" --list --unsorted)
assert_contains "$just_list" 'bootstrap host target'
assert_contains "$just_list" 'bootstrap-preflight host target'
if grep -Eq -- '--host-target|github:nix-community/(nixos-anywhere|disko)' "$justfile"; then
  fail 'justfile retains an invalid or unpinned bootstrap invocation'
fi
```

Add `pkgs.just` and `pkgs.gnugrep` to `checks.bootstrap-shell.nativeBuildInputs`.

- [ ] **Step 2: Verify the legacy recipes fail the test**

Run `bash tests/nixos-installer.sh scripts/nixos-installer.sh .`.

Expected: FAIL on the old `anywhere`/GitHub recipes.

- [ ] **Step 3: Replace the remote/bootstrap section**

Remove `anywhere`, `disko-mount-only`, `disko-install`, `disko-install-remount`, and `install-after-key`. Add `set unstable` and `set lists` near the top of the Justfile so variadic arguments retain their boundaries, then add:

```just
# Remote/bootstrap
# Validate a physical NixOS target without changing it
bootstrap-preflight host target *args:
    nix run .#bootstrap -- --host {{ quote(host) }} --target {{ quote(target) }} --preflight {{ quote(args) }}

# Install a physical NixOS target over SSH after preflight and typed confirmation
bootstrap host target *args:
    nix run .#bootstrap -- --host {{ quote(host) }} --target {{ quote(target) }} {{ quote(args) }}
```

Run `just --fmt --check` and `just --dry-run bootstrap acerus root@192.0.2.10 --ssh-auth key --ssh-key '/tmp/key with space'`. The rendered command must quote `acerus`, the target, each option, and `/tmp/key with space` as separate shell arguments.

- [ ] **Step 4: Verify discovery and absence of unpinned commands**

Run:

```bash
just --fmt --check
just --list --unsorted
bash tests/nixos-installer.sh scripts/nixos-installer.sh .
rg -n -- '--host-target|github:nix-community/(nixos-anywhere|disko)' justfile scripts nix
```

Expected: Just/test commands pass and `rg` has no matches.

- [ ] **Step 5: Commit**

```bash
git add justfile tests/nixos-installer.sh nix/bootstrap.nix
git commit -m "refactor(bootstrap): expose one supported ssh workflow"
```

---

### Task 7: Document Bootstrap and Profile Transition Operations

**Files:**
- Rewrite: `docs/nixos-installer-bootstrap-ssh.md`
- Modify: `README.md`
- Modify: `tests/nixos-installer.sh`

**Interfaces:**
- Consumes: final CLI, stable-disk rules, and existing Lanzaboote auto-enrollment configuration.
- Produces: an operator runbook for Acerus, Esquire, new physical hosts, and installer-to-daily transition.

- [ ] **Step 1: Add failing runbook assertions**

Append:

```bash
runbook=$repo_root/docs/nixos-installer-bootstrap-ssh.md
for expected in \
  'just bootstrap-preflight acerus root@' \
  'just bootstrap acerus root@' \
  '/dev/disk/by-id/' \
  'nixos-facter' \
  'acerus-installer' \
  'esquire-installer' \
  'Secure Boot Setup Mode' \
  'sbctl status' \
  'systemd-cryptenroll' \
  '--tpm2-pcrs=7'; do
  grep -Fq -- "$expected" "$runbook" || fail "runbook missing: $expected"
done
```

- [ ] **Step 2: Verify the current Esquire-only document fails**

Run `bash tests/nixos-installer.sh scripts/nixos-installer.sh .`.

Expected: FAIL on the first missing new command or Acerus transition anchor.

- [ ] **Step 3: Rewrite the runbook with fixed sections**

Use this structure:

```markdown
# Bootstrap a Physical NixOS Machine over SSH
## Safety Model
## Live Installer Preparation
## Source Machine Inputs
## Read-Only Preflight
## Password Authentication
## Existing SSH-Key Authentication
## Bootstrap a New SSH Key
## Confirm and Install
## Add a New Physical Host
## First Boot Checks
## Switch Acerus or Esquire to the Daily Profile
## Secure Boot Enrollment
## TPM2 Enrollment
## Failure Recovery
```

Include concrete Acerus and Esquire preflight/install examples. Explain that installation always includes preflight, while the standalone command is a dry-run readiness check. Show the exact `ERASE` form and both staged age-key paths without secret content.

For a new host, require these documented actions:

1. Record `lsblk -d -o PATH,SIZE,MODEL,SERIAL` from the live installer.
2. Find symlinks for the intended whole disk and prefer EUI/WWN under `/dev/disk/by-id/`.
3. Add `constants.hosts.<name>.systemDisk` and a host-level `lib.mkForce` override.
4. Generate nixos-facter separately, store it at the path expected by `<lib/define-hardware>`, review it, and wire the aspect deliberately.
5. Define both `<name>` and `<name>-installer` before preflight.

Document the current profile transition precisely: `/etc/secureboot` is persisted; firmware enters Setup Mode before daily activation; Lanzaboote generates keys, prepares automatic enrollment, and may reboot; `sbctl status` must pass before:

```bash
sudo systemd-cryptenroll \
  --tpm2-device=auto \
  --tpm2-pcrs=7 \
  /dev/disk/by-partlabel/root
```

State that the LUKS passphrase remains recovery and that an intentional PCR 7/key-policy change requires re-enrollment.

- [ ] **Step 4: Update README workflow descriptions**

Replace feature references to `disko-install`/`disko-install-remount` with `bootstrap`/`bootstrap-preflight`, link the runbook, and keep VPS language explicitly separate.

- [ ] **Step 5: Verify and commit**

Run:

```bash
bash tests/nixos-installer.sh scripts/nixos-installer.sh .
nix fmt -- --ci
```

Expected: tests and formatting pass. Commit:

```bash
git add docs/nixos-installer-bootstrap-ssh.md README.md tests/nixos-installer.sh
git commit -m "docs(bootstrap): describe ssh install and secure transition"
```

---

### Task 8: Verify the Complete Locked Workflow

**Files:**
- Verify: all files changed by Tasks 1–7
- Verify: `flake.lock`

**Interfaces:**
- Consumes: complete implementation.
- Produces: acceptance evidence for the NDD-95 handoff; no upstream writes.

- [ ] **Step 1: Run syntax, focused tests, discovery, and help**

```bash
bash -n scripts/nixos-installer.sh
bash -n tests/nixos-installer.sh
bash tests/nixos-installer.sh scripts/nixos-installer.sh .
just --fmt --check
just --list --unsorted
nix run path:.#bootstrap -- --help
```

Expected: all exit 0; Just exposes both supported commands; help lists every input and confirmation rule.

- [ ] **Step 2: Prove obsolete and unpinned invocations are absent**

```bash
rg -n -- '--host-target|github:nix-community/(nixos-anywhere|disko)' \
  justfile scripts nix modules docs/nixos-installer-bootstrap-ssh.md
```

Expected: no matches.

- [ ] **Step 3: Verify input generation and lock integrity**

```bash
nix flake metadata path:. --json | jq -e '.locks.nodes.root.inputs["nixos-anywhere"]'
nix flake lock --no-update-lock-file path:.
```

Expected: jq succeeds and lock validation makes no changes.

- [ ] **Step 4: Evaluate stable disks and run every flake check**

```bash
nix eval --raw path:.#nixosConfigurations.acerus-installer.config.disko.devices.disk.btrfs.device
nix eval --raw path:.#nixosConfigurations.esquire-installer.config.disko.devices.disk.btrfs.device
nix flake check path:. --print-build-logs
```

Expected: exact EUI paths and all checks pass.

- [ ] **Step 5: Run formatting and secret scanning**

```bash
nix fmt path:. -- --ci
nix run nixpkgs#gitleaks -- detect --source . --verbose
```

Expected: formatting passes and no plaintext secret is detected.

- [ ] **Step 6: Review local state without contacting upstream**

```bash
git status --short
git diff --stat
git log -8 --oneline
```

Expected: only NDD-95 files and focused task commits are present. Do not push, fetch, pull, or otherwise contact upstream.

- [ ] **Step 7: Record final verification evidence**

Report exact commands and outcomes. Do not mark NDD-95 complete in Linear until every automated acceptance command passes. If no real target is available, explicitly distinguish passing stub/evaluation coverage from the remaining live Acerus/Esquire SSH preflight.

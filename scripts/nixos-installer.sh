#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: bootstrap [OPTIONS]

Run the pinned nixos-anywhere bootstrap workflow for a physical NixOS host.

Options:
  --host HOST                         Physical host name (required).
  --target USER@ADDRESS               SSH destination (required).
  --age-identity PATH                 Age identity file (default: $HOME/.local/share/ages/keys.txt).
  --ssh-auth password|key|bootstrap-key
                                      SSH authentication mode (default: password).
  --ssh-key PATH                      Private SSH key for key or bootstrap-key authentication (default: unset).
  --build-on auto|local|remote        Where to build (default: auto).
  --preflight                          Run read-only validation and stop before installation (default: false).
  --help, -h                          Show this help text.

Destructive installations require typing the exact confirmation:
  ERASE <host> <disk>
where <host> is the physical host name and <disk> is its configured
/dev/disk/by-id/... device path.

Examples:
  nix run .#bootstrap -- --host acerus --target root@192.168.1.20
  just bootstrap acerus root@192.168.1.20
  just bootstrap-preflight acerus root@192.168.1.20
EOF
}

host=
target=
age_identity=${HOME:+$HOME/.local/share/ages/keys.txt}
ssh_auth=password
ssh_key=
build_on=auto
preflight=false
ssh_command=()
nixos_anywhere_ssh_options=()

while (($#)); do
  case $1 in
    --host|--target|--age-identity|--ssh-auth|--ssh-key|--build-on)
      (($# >= 2)) || { printf 'Error [arguments]: %s requires a value; run --help for usage.\n' "$1" >&2; exit 2; }
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
    *) printf 'Error [arguments]: unknown option: %s; run --help for usage.\n' "$1" >&2; usage >&2; exit 2 ;;
  esac
done

BOOTSTRAP_FLAKE_SOURCE=${BOOTSTRAP_FLAKE_SOURCE:-.}

die() {
  local stage=$1
  shift
  printf 'Error [%s]: %s\n' "$stage" "$*" >&2
  exit 1
}

validate_arguments() {
  [[ -n $host ]] || die arguments '--host is required; provide a physical host name.'
  [[ -n $target ]] || die arguments '--target is required; provide USER@ADDRESS.'
  [[ $host =~ ^[A-Za-z0-9][A-Za-z0-9_-]*$ ]] || die arguments "invalid host '$host'; use one host attribute name with letters, digits, '_' or '-'."
  [[ $target =~ ^[^@[:space:]-][^@[:space:]]*@[^@[:space:]]+$ ]] || die arguments "invalid target '$target'; use USER@ADDRESS with exactly one @, no whitespace, and no leading dash."
  case $ssh_auth in
    password|key|bootstrap-key) ;;
    *) die arguments "invalid SSH authentication mode '$ssh_auth'; choose password, key, or bootstrap-key." ;;
  esac
  case $build_on in
    auto|local|remote) ;;
    *) die arguments "invalid build mode '$build_on'; choose auto, local, or remote." ;;
  esac
  if [[ $ssh_auth == key || $ssh_auth == bootstrap-key ]]; then
    [[ -n $ssh_key ]] || die arguments '--ssh-key is required for key authentication; provide a readable private key and .pub companion.'
    [[ -r $ssh_key ]] || die ssh "private key is not readable: $ssh_key; check --ssh-key and its permissions."
    [[ -r $ssh_key.pub ]] || die ssh "public key is not readable: $ssh_key.pub; create the matching public-key companion."
  fi
}

resolve_configuration() {
  physical_host=${host%-installer}
  if [[ $host == *-installer ]]; then
    installer_host=$host
  else
    installer_host=$host-installer
  fi
  local attr="$BOOTSTRAP_FLAKE_SOURCE#nixosConfigurations.$installer_host.config"
  host_system=$(nix eval --raw "$attr.nixpkgs.hostPlatform.system" 2>/dev/null) ||
    die configuration "cannot evaluate nixosConfigurations.$installer_host; check that the installer profile exists, then rerun preflight."
  local disks_json disk_count
  disks_json=$(nix eval --json "$attr.disko.devices.disk" 2>/dev/null) ||
    die configuration "cannot evaluate Disko disks for $installer_host; check the installer Disko configuration, then rerun preflight."
  disk_count=$(jq -er 'if type == "object" then length else error("Disko disks must be an object") end' <<<"$disks_json" 2>/dev/null) ||
    die configuration "Disko evaluation for $installer_host returned invalid JSON; check the installer Disko configuration and rerun preflight."
  [[ $disk_count == 1 ]] || die configuration "$installer_host must define exactly one top-level Disko disk (found $disk_count); remove extra disks and rerun preflight."
  disko_device=$(jq -er 'to_entries[0].value.device | select(type == "string")' <<<"$disks_json" 2>/dev/null) ||
    die configuration "$installer_host does not define a string Disko device; set its systemDisk and rerun preflight."
  [[ $disko_device == /dev/disk/by-id/* ]] ||
    die configuration "Disko device '$disko_device' is not stable; set systemDisk to a /dev/disk/by-id/ path and rerun preflight."
}

validate_sops() {
  [[ -r $age_identity ]] || die secrets "age identity is not readable: $age_identity; check --age-identity and its permissions."
  local attr="$BOOTSTRAP_FLAKE_SOURCE#nixosConfigurations.$installer_host.config.sops"
  local files_json sops_files_json encrypted_file
  files_json=$(nix eval --json "$attr" --apply \
    'sops: let defaultFile = if (sops.defaultSopsFile or null) == null then [ ] else [ (toString sops.defaultSopsFile) ]; secretFiles = builtins.attrValues (sops.secrets or { }); overrideFiles = builtins.filter (file: file != null) (builtins.map (secret: secret.sopsFile or null) secretFiles); in defaultFile ++ builtins.map toString overrideFiles' \
    2>/dev/null) || die secrets "cannot evaluate SOPS files for $installer_host; check defaultSopsFile and per-secret sopsFile settings, then rerun preflight."
  sops_files_json=$(jq -cer 'if type == "array" and all(.[]; type == "string" and length > 0) then unique else error("SOPS files must be non-empty strings") end' <<<"$files_json" 2>/dev/null) ||
    die secrets "SOPS file projection for $installer_host is invalid; check defaultSopsFile and per-secret sopsFile settings."
  mapfile -t sops_files < <(jq -er '.[]' <<<"$sops_files_json")
  ((${#sops_files[@]} > 0)) || die secrets "$installer_host has no required SOPS files; set defaultSopsFile or a per-secret sopsFile and rerun preflight."
  for encrypted_file in "${sops_files[@]}"; do
    SOPS_AGE_KEY_FILE=$age_identity sops decrypt --output /dev/null "$encrypted_file" >/dev/null 2>&1 ||
      die secrets "cannot decrypt required SOPS file '$encrypted_file'; verify the age identity and SOPS recipients, then rerun preflight."
    printf 'SOPS               : OK (%s)\n' "$encrypted_file"
  done
}

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

inspect_remote_disk() {
  local remote_json ssh_status remote_blockdevice_count
  if remote_json=$("${ssh_command[@]}" "$target" bash -s -- "$disko_device" 2>/dev/null <<'REMOTE_SCRIPT'
set -euo pipefail
configured_disk=$1
[[ -e $configured_disk ]] || exit 4
resolved=$(readlink -f -- "$configured_disk") || exit 4
lsblk --json --bytes --nodeps --output PATH,TYPE,SIZE,MODEL,SERIAL "$resolved"
REMOTE_SCRIPT
  ); then
    :
  else
    ssh_status=$?
    if [[ $ssh_status == 4 ]]; then
      die disk "configured device '$disko_device' is missing on target '$target'; verify the stable by-id symlink and rerun preflight."
    fi
    die ssh "remote disk inspection failed for target '$target' (ssh exit $ssh_status); check SSH connectivity and authentication, then rerun preflight."
  fi

  remote_blockdevice_count=$(jq -er '
    if (.blockdevices | type) != "array" then
      error("blockdevices is not an array")
    else
      .blockdevices | length
    end
  ' <<<"$remote_json" 2>/dev/null) || die disk "target '$target' returned invalid lsblk JSON for '$disko_device'; check lsblk on the live installer and rerun preflight."
  [[ $remote_blockdevice_count == 1 ]] || die disk "configured device '$disko_device' on target '$target' resolved to $remote_blockdevice_count block devices; use one whole-disk by-id path and rerun preflight."

  jq -e '.blockdevices[0] | select(.type == "disk") | select(.path | type == "string" and length > 0)' <<<"$remote_json" >/dev/null 2>&1 ||
    die disk "configured device '$disko_device' on target '$target' did not resolve to one whole disk with a valid path; avoid partitions and mappers, then rerun preflight."

  resolved_disk=$(jq -er '.blockdevices[0].path' <<<"$remote_json" 2>/dev/null) ||
    die disk "target '$target' returned no resolved disk path for '$disko_device'; check lsblk and the by-id symlink, then rerun preflight."
  resolved_disk_size=$(jq -er '.blockdevices[0].size | select(type == "number")' <<<"$remote_json" 2>/dev/null) ||
    die disk "resolved disk '$resolved_disk' on target '$target' has no numeric size; check lsblk output and rerun preflight."
  resolved_disk_model=$(jq -er '.blockdevices[0].model | if type == "string" then if length > 0 then . else "unknown" end else "unknown" end' <<<"$remote_json" 2>/dev/null) ||
    die disk "resolved disk '$resolved_disk' on target '$target' has invalid model metadata; check lsblk output and rerun preflight."
  resolved_disk_serial=$(jq -er '.blockdevices[0].serial | if type == "string" then if length > 0 then . else "unknown" end else "unknown" end' <<<"$remote_json" 2>/dev/null) ||
    die disk "resolved disk '$resolved_disk' on target '$target' has invalid serial metadata; check lsblk output and rerun preflight."
}

bootstrap_ssh_key() {
  [[ $ssh_auth == bootstrap-key ]] || return 0
  ssh-copy-id -i "$ssh_key.pub" \
    -o PreferredAuthentications=password \
    -o PubkeyAuthentication=no \
    "$target" >/dev/null ||
    die ssh "could not install public key on target '$target'; verify the temporary password, sshd, and public key '$ssh_key.pub', then retry."
  ssh_auth=key
  printf 'SSH public key installed: %s\n' "$ssh_key.pub"
  configure_ssh
  inspect_remote_disk
}

confirm_destruction() {
  local expected reply
  expected="ERASE $physical_host $disko_device"
  printf 'Type exactly: %s\n' "$expected"
  reply=$(gum input --prompt '> ') || {
    die confirmation "Installation cancelled for $physical_host: no confirmation received; review the summary and type exactly '$expected'."
  }
  if [[ $reply != "$expected" ]]; then
    die confirmation "Installation cancelled for $physical_host: confirmation did not match; review the summary and type exactly '$expected'."
  fi
}

staging_root=

cleanup() {
  local candidate=${staging_root:-}
  local temp_parent=${TMPDIR:-/tmp}
  [[ -n $candidate && $candidate == "$temp_parent"/nixos-bootstrap.* ]] || return 0
  [[ $candidate != "$temp_parent" && $candidate != /tmp && -d $candidate ]] || return 0
  if rm -rf -- "$candidate" >/dev/null 2>&1; then
    staging_root=
  else
    printf 'Error [staging]: could not remove temporary SOPS staging; clean the generated temporary directory before retrying.\n' >&2
    return 1
  fi
}

handle_signal() {
  local status=$1
  trap - INT TERM
  printf 'Error [staging]: interrupted (exit %s); temporary SOPS staging was cleaned, so rerun preflight before retrying.\n' "$status" >&2
  cleanup
  exit "$status"
}

stage_age_identity() {
  umask 077
  staging_root=$(mktemp -d "${TMPDIR:-/tmp}/nixos-bootstrap.XXXXXXXX" 2>/dev/null) ||
    die staging "could not create temporary staging under ${TMPDIR:-/tmp}; check writable temporary storage and retry."
  trap cleanup EXIT
  trap 'handle_signal 130' INT
  trap 'handle_signal 143' TERM
  install -d -m 0700 "$staging_root/var/lib/sops-nix" "$staging_root/persist/var/lib/sops-nix" >/dev/null 2>&1 ||
    die staging 'could not create SOPS staging directories; check writable temporary storage and retry.'
  install -m 0600 "$age_identity" "$staging_root/var/lib/sops-nix/keys.txt" >/dev/null 2>&1 ||
    die staging 'could not stage the SOPS age identity at /var/lib/sops-nix/keys.txt; check --age-identity and temporary storage.'
  install -m 0600 "$age_identity" "$staging_root/persist/var/lib/sops-nix/keys.txt" >/dev/null 2>&1 ||
    die staging 'could not stage the SOPS age identity at /persist/var/lib/sops-nix/keys.txt; check --age-identity and temporary storage.'
}

run_install() {
  if nixos-anywhere \
    --flake "$BOOTSTRAP_FLAKE_SOURCE#$installer_host" \
    --build-on "$build_on" \
    --extra-files "$staging_root" \
    "${nixos_anywhere_ssh_options[@]}" \
    "$target" >/dev/null 2>&1; then
    :
  else
    local status=$?
    printf 'Error [install]: nixos-anywhere failed for target %s (exit %s); inspect the target state and rerun preflight before retrying.\n' "$target" "$status" >&2
    return "$status"
  fi
}

print_summary() {
  printf '%-19s: %s\n' 'Host' "$physical_host"
  printf '%-19s: %s\n' 'Configuration' "$installer_host"
  printf '%-19s: %s\n' 'Architecture' "$host_system"
  printf '%-19s: %s\n' 'Target' "$target"
  printf '%-19s: %s\n' 'Build on' "$build_on"
  printf '%-19s: %s\n' 'Configured disk' "$disko_device"
  printf '%-19s: %s\n' 'Resolved disk' "$resolved_disk"
  printf '%-19s: %s bytes\n' 'Size' "$resolved_disk_size"
  printf '%-19s: %s\n' 'Model' "$resolved_disk_model"
  printf '%-19s: %s\n' 'Serial' "$resolved_disk_serial"
}

validate_arguments
resolve_configuration
validate_sops
configure_ssh
inspect_remote_disk
print_summary
if $preflight; then
  printf '%-19s: READY\n' 'Preflight'
  exit 0
fi

bootstrap_ssh_key
confirm_destruction
stage_age_identity
run_install
printf 'Installation command completed for %s.\n' "$physical_host"

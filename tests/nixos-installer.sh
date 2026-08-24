#!/usr/bin/env bash
set -euo pipefail

script=${1:-"$(cd -- "$(dirname -- "$0")/.." && pwd)/scripts/nixos-installer.sh"}
repo_root=${2:-"$(cd -- "$(dirname -- "$script")/.." && pwd)"}
repo_root=$(cd -- "$repo_root" && pwd)
test_root=$(mktemp -d)
trap 'rm -rf -- "$test_root"' EXIT INT TERM

fail() { printf 'FAIL: %s\n' "$*" >&2; exit 1; }
assert_contains() {
  local haystack=$1 needle=$2
  [[ $haystack == *"$needle"* ]] || fail "missing output: $needle"
}

original_path=$PATH

new_case() {
  case_dir=$test_root/case-$RANDOM
  stub_dir=$case_dir/bin
  log_dir=$case_dir/log
  tmp_dir=$case_dir/tmp
  mkdir -p "$stub_dir" "$log_dir" "$tmp_dir"
  export BOOTSTRAP_TEST_LOG=$log_dir
  export PATH=$stub_dir:$original_path
  export TMPDIR=$tmp_dir
  age_file=$case_dir/keys.txt
  printf 'AGE-SECRET-KEY-1TESTFIXTURE\n' >"$age_file"
  chmod 600 "$age_file"
  ssh_key=$case_dir/id_ed25519
  printf 'SSH-PRIVATE-KEY-TEST-FIXTURE\n' >"$ssh_key"
  printf 'ssh-ed25519 TEST-FIXTURE\n' >"$ssh_key.pub"
  chmod 600 "$ssh_key"
  chmod 644 "$ssh_key.pub"
  export BOOTSTRAP_SSH_MODE=disk
  unset BOOTSTRAP_NIXOS_ANYWHERE_SIGNAL
  unset BOOTSTRAP_SOPS_FILES_OVERRIDE
}

write_stub() {
  local name=$1
  shift
  {
    printf '#!%s\n' "$(command -v bash)"
    printf '%s\n' 'set -euo pipefail'
    printf '%s\n' "$@"
  } >"$stub_dir/$name"
  chmod +x "$stub_dir/$name"
}

run_capture() {
  set +e
  output=$(BOOTSTRAP_FLAKE_SOURCE="$repo_root" bash "$script" "$@" 2>&1)
  status=$?
  set -e
}

assert_status() {
  [[ $status == "$1" ]] || fail "expected status $1, got $status: $output"
}

assert_sops_call() {
  local log=$1 age_file=$2 encrypted_file=$3
  assert_contains "$log" "$age_file|decrypt --output /dev/null $encrypted_file"
}

assert_no_destructive_calls() {
  [[ ! -e $log_dir/gum ]] || fail "$1 invoked Gum"
  [[ ! -e $log_dir/ssh-copy-id ]] || fail "$1 invoked ssh-copy-id"
  [[ ! -e $log_dir/nixos-anywhere ]] || fail "$1 invoked nixos-anywhere"
}

assert_tmp_clean() {
  local leaked
  leaked=$(find "$tmp_dir" -mindepth 1 -maxdepth 1 -print -quit)
  [[ -z $leaked ]] || fail "temporary staging leaked: $leaked"
}

assert_no_install_or_secret_leak() {
  [[ ! -e $log_dir/nixos-anywhere ]] || fail "$1 invoked nixos-anywhere"
  [[ $output != *AGE-SECRET-KEY-1TESTFIXTURE* ]] || fail "$1 leaked the fixture secret"
  assert_tmp_clean
}

justfile=$repo_root/justfile
just_list=$(just --justfile "$justfile" --list --unsorted)
assert_contains "$just_list" 'bootstrap host target'
assert_contains "$just_list" 'bootstrap-preflight host target'
if grep -Eq -- '--host-target|github:nix-community/(nixos-anywhere|disko)' "$justfile"; then
  fail 'justfile retains an invalid or unpinned bootstrap invocation'
fi
bootstrap_module=$repo_root/nix/bootstrap.nix
grep -Fq 'builtins.hasAttr "nixos-anywhere" inputs' "$bootstrap_module" ||
  fail 'bootstrap module lacks a missing-input presence guard'
grep -Fq "builtins.hasAttr \"packages\" inputs'.nixos-anywhere" "$bootstrap_module" ||
  fail 'bootstrap module lacks a missing-packages presence guard'

assert_arg_order() {
  local log_file=$1
  shift
  local line index=0
  local -a expected=("$@")
  while IFS= read -r line; do
    if [[ $index -lt ${#expected[@]} && $line == "${expected[index]}" ]]; then
      index=$((index + 1))
    fi
  done <"$log_file"
  [[ $index == ${#expected[@]} ]] || fail "nixos-anywhere arguments were out of order"
}

write_common_stubs() {
  write_stub nix \
    'printf "%s\\n" "$*" >>"$BOOTSTRAP_TEST_LOG/nix"' \
    'if [[ $* == *acerus-installer.config.sops* && -n ${BOOTSTRAP_SOPS_FILES_OVERRIDE:-} ]]; then printf "%s\\n" "$BOOTSTRAP_SOPS_FILES_OVERRIDE"; exit 0; fi' \
    'case "$BOOTSTRAP_NIX_MODE:$*" in' \
    '  missing-host:*) exit 1 ;;' \
    '  raw-disk:*disko.devices.disk*) printf "%s\\n" '"'"'{"btrfs":{"device":"/dev/nvme0n1"}}'"'"' ;;' \
    '  two-disks:*disko.devices.disk*) printf "%s\\n" '"'"'{"btrfs":{"device":"/dev/disk/by-id/nvme-eui.e8238fa6bf530001001b448b47e55428"},"extra":{"device":"/dev/disk/by-id/extra"}}'"'"' ;;' \
    '  *:*) case "$*" in' \
    '    *acerus-installer.config.nixpkgs.hostPlatform.system*) printf "%s" x86_64-linux ;;' \
    '    *acerus-installer.config.disko.devices.disk*) printf "%s\\n" '"'"'{"btrfs":{"device":"/dev/disk/by-id/nvme-eui.e8238fa6bf530001001b448b47e55428"}}'"'"' ;;' \
    '    *acerus-installer.config.sops*) printf "%s\\n" '"'"'["/nix/store/test-acerus-secrets.yaml","/nix/store/test-shared-secrets.yaml"]'"'"' ;;' \
    '    *) exit 1 ;;' \
    '  esac ;;' \
    'esac'
  write_stub sops \
    'printf "%s|%s\\n" "${SOPS_AGE_KEY_FILE-UNSET}" "$*" >>"$BOOTSTRAP_TEST_LOG/sops"' \
    'if [[ ${BOOTSTRAP_SOPS_MODE:-success} == fail ]]; then' \
    '  printf "%s\\n" AGE-SECRET-KEY-1TESTFIXTURE' \
    '  exit 1' \
    'fi'
  write_stub ssh \
    'printf "%s\\n" ssh >>"$BOOTSTRAP_TEST_LOG/events"' \
    'printf "%s\\n" "$*" >>"$BOOTSTRAP_TEST_LOG/ssh"' \
    'cat >"$BOOTSTRAP_TEST_LOG/ssh-stdin"' \
    'case ${BOOTSTRAP_SSH_MODE:-disk} in' \
    '  disk) printf "%s\\n" '\''{"blockdevices":[{"path":"/dev/nvme0n1","type":"disk","size":1024209543168,"model":"WD PC SN740 SDDQNQD-1T00-1014","serial":"240960811264"}]} '\'' ;;' \
    '  partition) printf "%s\\n" '\''{"blockdevices":[{"path":"/dev/nvme0n1p1","type":"part","size":1073741824,"model":"WD PC SN740","serial":"240960811264"}]} '\'' ;;' \
    '  mapper) printf "%s\\n" '\''{"blockdevices":[{"path":"/dev/mapper/cryptroot","type":"crypt","size":1024209543168,"model":"WD PC SN740","serial":"240960811264"}]} '\'' ;;' \
    '  empty) printf "%s\\n" '\''{"blockdevices":[]} '\'' ;;' \
    '  multiple-disks) printf "%s\\n" '\''{"blockdevices":[{"path":"/dev/nvme0n1","type":"disk","size":1024209543168,"model":"WD PC SN740","serial":"240960811264"},{"path":"/dev/sda","type":"disk","size":1000204886016,"model":"USB Disk","serial":"TEST"}]} '\'' ;;' \
    '  mixed) printf "%s\\n" '\''{"blockdevices":[{"path":"/dev/nvme0n1","type":"disk","size":1024209543168,"model":"WD PC SN740","serial":"240960811264"},{"path":"/dev/nvme0n1p1","type":"part","size":1073741824,"model":"WD PC SN740","serial":"240960811264"}]} '\'' ;;' \
    '  malformed) printf "%s\\n" '\''{"blockdevices":[}'\'' ;;' \
    '  null-path) printf "%s\\n" '\''{"blockdevices":[{"path":null,"type":"disk","size":1024209543168,"model":"WD PC SN740","serial":"240960811264"}]} '\'' ;;' \
    '  nonstring-path) printf "%s\\n" '\''{"blockdevices":[{"path":{"device":"/dev/nvme0n1"},"type":"disk","size":1024209543168,"model":"WD PC SN740","serial":"240960811264"}]} '\'' ;;' \
    '  metadata-missing) printf "%s\\n" '\''{"blockdevices":[{"path":"/dev/nvme0n1","type":"disk","size":1024209543168}]} '\'' ;;' \
    '  metadata-null-empty) printf "%s\\n" '\''{"blockdevices":[{"path":"/dev/nvme0n1","type":"disk","size":1024209543168,"model":null,"serial":""}]} '\'' ;;' \
    '  metadata-nonstring) printf "%s\\n" '\''{"blockdevices":[{"path":"/dev/nvme0n1","type":"disk","size":1024209543168,"model":{"name":"WD PC SN740"},"serial":["240960811264"]}]} '\'' ;;' \
    '  metadata-boolean) printf "%s\\n" '\''{"blockdevices":[{"path":"/dev/nvme0n1","type":"disk","size":1024209543168,"model":false,"serial":true}]} '\'' ;;' \
    '  missing) exit 4 ;;' \
    '  unreachable) exit 255 ;;' \
    '  *) exit 1 ;;' \
    'esac'
  write_stub gum \
    'touch "$BOOTSTRAP_TEST_LOG/gum"' \
    'printf "%s\n" gum >>"$BOOTSTRAP_TEST_LOG/events"' \
    'if [[ ${BOOTSTRAP_GUM_MODE:-fail} == fail ]]; then exit 1; fi' \
    'printf "%s\n" "${BOOTSTRAP_GUM_REPLY-}"'
  write_stub ssh-copy-id \
    'touch "$BOOTSTRAP_TEST_LOG/ssh-copy-id"' \
    'printf "%s\n" ssh-copy-id >>"$BOOTSTRAP_TEST_LOG/events"' \
    'printf "%s\n" "$*" >"$BOOTSTRAP_TEST_LOG/ssh-copy-id-args"'
  write_stub nixos-anywhere \
    'touch "$BOOTSTRAP_TEST_LOG/nixos-anywhere"' \
    'printf "%s\n" nixos-anywhere >>"$BOOTSTRAP_TEST_LOG/events"' \
    'printf "%s\n" "$@" >"$BOOTSTRAP_TEST_LOG/nixos-anywhere-args"' \
    'args=("$@")' \
    'for ((index=0; index<${#args[@]}; index++)); do' \
    '  if [[ ${args[index]} == --extra-files ]]; then' \
    '    extra_files=${args[index+1]-}' \
    '    break' \
    '  fi' \
    'done' \
    '[[ -n ${extra_files:-} ]]' \
    'test -f "$extra_files/var/lib/sops-nix/keys.txt"' \
    'test -f "$extra_files/persist/var/lib/sops-nix/keys.txt"' \
    'test "$(stat -c %a "$extra_files/var/lib/sops-nix/keys.txt")" = 600' \
    'test "$(stat -c %a "$extra_files/persist/var/lib/sops-nix/keys.txt")" = 600' \
    'printf "%s\n" "$extra_files" >"$BOOTSTRAP_TEST_LOG/staging-root"' \
    'if [[ -n ${BOOTSTRAP_NIXOS_ANYWHERE_SIGNAL:-} ]]; then' \
    '  kill "-${BOOTSTRAP_NIXOS_ANYWHERE_SIGNAL}" "$PPID"' \
    '  exit 0' \
    'fi' \
    'exit "${BOOTSTRAP_NIXOS_ANYWHERE_STATUS:-0}"'
}

help_output=$(bash "$script" --help)
for expected in '--host HOST' '--target USER@ADDRESS' '--age-identity PATH' \
  '--ssh-auth password|key|bootstrap-key' '--ssh-key PATH' \
  'Private SSH key for key or bootstrap-key authentication (default: unset).' \
  '--build-on auto|local|remote' '--preflight' \
  'Run read-only validation and stop before installation (default: false).' 'ERASE'; do
  assert_contains "$help_output" "$expected"
done

new_case
export BOOTSTRAP_NIX_MODE=success
export BOOTSTRAP_SOPS_MODE=success
export BOOTSTRAP_SOPS_FILES_OVERRIDE='["/nix/store/test-acerus-default-secrets.yaml","/nix/store/test-shared-secrets.yaml","/nix/store/test-shared-secrets.yaml"]'
write_common_stubs
run_capture --host acerus --target root@192.0.2.10 --age-identity "$age_file" --preflight
assert_status 0
[[ -e $log_dir/nix ]] || fail 'preflight did not evaluate configuration'
acerus_nix_log=$(<"$log_dir/nix")
assert_contains "$acerus_nix_log" "$repo_root#nixosConfigurations.acerus-installer.config.nixpkgs.hostPlatform.system"
sops_log=$(<"$log_dir/sops")
assert_sops_call "$sops_log" "$age_file" /nix/store/test-acerus-default-secrets.yaml
assert_sops_call "$sops_log" "$age_file" /nix/store/test-shared-secrets.yaml
[[ $(wc -l <"$log_dir/sops") == 2 ]] || fail 'SOPS did not verify exactly two effective files'
[[ $(grep -cF "/nix/store/test-acerus-default-secrets.yaml" "$log_dir/sops") == 1 ]] ||
  fail 'default SOPS file was not decrypted exactly once'
[[ $(grep -cF "/nix/store/test-shared-secrets.yaml" "$log_dir/sops") == 1 ]] ||
  fail 'override SOPS file was not deduplicated to one decrypt'

new_case
export BOOTSTRAP_NIX_MODE=success
export BOOTSTRAP_SOPS_MODE=success
write_common_stubs
run_capture --host acerus-installer --target root@192.0.2.10 --age-identity "$age_file" --preflight
assert_status 0
[[ -e $log_dir/nix ]] || fail 'explicit installer preflight did not evaluate configuration'
installer_nix_log=$(<"$log_dir/nix")
[[ $acerus_nix_log == "$installer_nix_log" ]] || fail 'physical and explicit installer hosts resolved differently'

new_case
export BOOTSTRAP_NIX_MODE=missing-host
write_common_stubs
run_capture --host missing --target root@192.0.2.10 --age-identity "$age_file" --preflight
assert_status 1
assert_contains "$output" 'Error [configuration]'
assert_contains "$output" 'check that the installer profile exists'
[[ ! -e $log_dir/sops ]] || fail 'SOPS ran for a missing host'
[[ ! -e $log_dir/ssh ]] || fail 'SSH ran for a missing host'

new_case
export BOOTSTRAP_NIX_MODE=success
write_common_stubs
run_capture --host acerus.invalid --target root@192.0.2.10 --age-identity "$age_file" --preflight
assert_status 1
assert_contains "$output" 'Error [arguments]'
[[ ! -e $log_dir/nix ]] || fail 'Nix ran for a dotted host'
[[ ! -e $log_dir/sops ]] || fail 'SOPS ran for a dotted host'
[[ ! -e $log_dir/ssh ]] || fail 'SSH ran for a dotted host'

invalid_targets=(
  '-root@192.0.2.10'
  '@192.0.2.10'
  'root@'
  'root@192.0.2.10@extra'
  'root@192.0.2.10 with space'
)
for invalid_target in "${invalid_targets[@]}"; do
  new_case
  export BOOTSTRAP_NIX_MODE=success
  write_common_stubs
  run_capture --host acerus --target "$invalid_target" --age-identity "$age_file" --preflight
  assert_status 1
  assert_contains "$output" 'Error [arguments]'
  [[ ! -e $log_dir/nix ]] || fail "Nix ran for invalid target: $invalid_target"
  [[ ! -e $log_dir/sops ]] || fail "SOPS ran for invalid target: $invalid_target"
  [[ ! -e $log_dir/ssh ]] || fail "SSH ran for invalid target: $invalid_target"
done

new_case
export BOOTSTRAP_NIX_MODE=raw-disk
write_common_stubs
run_capture --host acerus --target root@192.0.2.10 --age-identity "$age_file" --preflight
assert_status 1
assert_contains "$output" 'Error [configuration]'
assert_contains "$output" 'set systemDisk to a /dev/disk/by-id/ path'
[[ ! -e $log_dir/sops ]] || fail 'SOPS ran for a raw Disko device'
[[ ! -e $log_dir/ssh ]] || fail 'SSH ran for a raw Disko device'

new_case
export BOOTSTRAP_NIX_MODE=two-disks
write_common_stubs
run_capture --host acerus --target root@192.0.2.10 --age-identity "$age_file" --preflight
assert_status 1
assert_contains "$output" 'Error [configuration]'
[[ ! -e $log_dir/sops ]] || fail 'SOPS ran for multiple Disko disks'
[[ ! -e $log_dir/ssh ]] || fail 'SSH ran for multiple Disko disks'

new_case
export BOOTSTRAP_NIX_MODE=success
write_common_stubs
missing_age=$case_dir/missing-keys.txt
run_capture --host acerus --target root@192.0.2.10 --age-identity "$missing_age" --preflight
assert_status 1
assert_contains "$output" 'Error [secrets]'
[[ ! -e $log_dir/sops ]] || fail 'SOPS ran without an age identity'
[[ ! -e $log_dir/ssh ]] || fail 'SSH ran without an age identity'

new_case
export BOOTSTRAP_NIX_MODE=success
export BOOTSTRAP_SOPS_MODE=fail
write_common_stubs
run_capture --host acerus --target root@192.0.2.10 --age-identity "$age_file" --preflight
assert_status 1
assert_contains "$output" 'Error [secrets]'
assert_contains "$output" 'verify the age identity and SOPS recipients'
[[ $output != *AGE-SECRET-KEY-1TESTFIXTURE* ]] || fail 'SOPS failure leaked fixture secret'
[[ ! -e $log_dir/ssh ]] || fail 'SSH ran after SOPS failure'

new_case
export BOOTSTRAP_NIX_MODE=success
export BOOTSTRAP_SOPS_MODE=success
write_common_stubs
run_capture --host acerus --target root@192.0.2.10 --age-identity "$age_file" --preflight
assert_status 0
for expected in \
  'Host               : acerus' \
  'Configuration      : acerus-installer' \
  'Architecture       : x86_64-linux' \
  'Target             : root@192.0.2.10' \
  'Build on           : auto' \
  'Configured disk    : /dev/disk/by-id/nvme-eui.e8238fa6bf530001001b448b47e55428' \
  'Resolved disk      : /dev/nvme0n1' \
  'Size               : 1024209543168 bytes' \
  'Model              : WD PC SN740 SDDQNQD-1T00-1014' \
  'Serial             : 240960811264' \
  'Preflight          : READY'; do
  assert_contains "$output" "$expected"
done
[[ ! -e $log_dir/gum ]] || fail 'valid preflight invoked Gum'
[[ ! -e $log_dir/ssh-copy-id ]] || fail 'valid preflight invoked ssh-copy-id'
[[ ! -e $log_dir/nixos-anywhere ]] || fail 'valid preflight invoked nixos-anywhere'
ssh_log=$(<"$log_dir/ssh")
assert_contains "$ssh_log" '-o ConnectTimeout=10 -o PreferredAuthentications=password -o PubkeyAuthentication=no root@192.0.2.10 bash -s -- /dev/disk/by-id/nvme-eui.e8238fa6bf530001001b448b47e55428'
remote_program=$(<"$log_dir/ssh-stdin")
assert_contains "$remote_program" 'configured_disk=$1'
assert_contains "$remote_program" 'lsblk --json --bytes --nodeps --output PATH,TYPE,SIZE,MODEL,SERIAL "$resolved"'
[[ $remote_program != *'/dev/disk/by-id/nvme-eui.e8238fa6bf530001001b448b47e55428'* ]] || fail 'remote program interpolated configured disk'

new_case
export BOOTSTRAP_NIX_MODE=success
export BOOTSTRAP_SOPS_MODE=success
export BOOTSTRAP_SSH_MODE=partition
write_common_stubs
run_capture --host acerus --target root@192.0.2.10 --age-identity "$age_file" --preflight
assert_status 1
assert_contains "$output" 'Error [disk]'
assert_contains "$output" 'avoid partitions and mappers'
[[ ! -e $log_dir/gum ]] || fail 'partition failure invoked Gum'
[[ ! -e $log_dir/ssh-copy-id ]] || fail 'partition failure invoked ssh-copy-id'
[[ ! -e $log_dir/nixos-anywhere ]] || fail 'partition failure invoked nixos-anywhere'

new_case
export BOOTSTRAP_NIX_MODE=success
export BOOTSTRAP_SOPS_MODE=success
export BOOTSTRAP_SSH_MODE=missing
write_common_stubs
run_capture --host acerus --target root@192.0.2.10 --age-identity "$age_file" --preflight
assert_status 1
assert_contains "$output" 'Error [disk]'
[[ ! -e $log_dir/gum ]] || fail 'missing-device failure invoked Gum'
[[ ! -e $log_dir/ssh-copy-id ]] || fail 'missing-device failure invoked ssh-copy-id'
[[ ! -e $log_dir/nixos-anywhere ]] || fail 'missing-device failure invoked nixos-anywhere'

new_case
export BOOTSTRAP_NIX_MODE=success
export BOOTSTRAP_SOPS_MODE=success
export BOOTSTRAP_SSH_MODE=unreachable
write_common_stubs
run_capture --host acerus --target root@192.0.2.10 --age-identity "$age_file" --preflight
assert_status 1
assert_contains "$output" 'Error [ssh]'
assert_contains "$output" 'check SSH connectivity and authentication'
[[ ! -e $log_dir/gum ]] || fail 'unreachable SSH invoked Gum'
[[ ! -e $log_dir/ssh-copy-id ]] || fail 'unreachable SSH invoked ssh-copy-id'
[[ ! -e $log_dir/nixos-anywhere ]] || fail 'unreachable SSH invoked nixos-anywhere'

for remote_shape in mapper empty multiple-disks mixed malformed null-path nonstring-path; do
  new_case
  export BOOTSTRAP_NIX_MODE=success
  export BOOTSTRAP_SOPS_MODE=success
  export BOOTSTRAP_SSH_MODE=$remote_shape
  write_common_stubs
  run_capture --host acerus --target root@192.0.2.10 --age-identity "$age_file" --preflight
  assert_status 1
  assert_contains "$output" 'Error [disk]'
  assert_no_destructive_calls "$remote_shape shape failure"
done

for metadata_shape in metadata-missing metadata-null-empty metadata-nonstring metadata-boolean; do
  new_case
  export BOOTSTRAP_NIX_MODE=success
  export BOOTSTRAP_SOPS_MODE=success
  export BOOTSTRAP_SSH_MODE=$metadata_shape
  write_common_stubs
  run_capture --host acerus --target root@192.0.2.10 --age-identity "$age_file" --preflight
  assert_status 0
  assert_contains "$output" 'Model              : unknown'
  assert_contains "$output" 'Serial             : unknown'
  assert_no_destructive_calls "$metadata_shape metadata"
done
script_source=$(<"$script")
assert_contains "$script_source" '.blockdevices[0].model | if type == "string" then if length > 0 then . else "unknown" end else "unknown" end'
assert_contains "$script_source" '.blockdevices[0].serial | if type == "string" then if length > 0 then . else "unknown" end else "unknown" end'

for confirmation_case in no eof wrong-host; do
  new_case
  export BOOTSTRAP_NIX_MODE=success
  export BOOTSTRAP_SOPS_MODE=success
  export BOOTSTRAP_SSH_MODE=disk
  export BOOTSTRAP_NIXOS_ANYWHERE_STATUS=0
  write_common_stubs
  case $confirmation_case in
    no)
      export BOOTSTRAP_GUM_MODE=success
      export BOOTSTRAP_GUM_REPLY=NO
      ;;
    eof)
      export BOOTSTRAP_GUM_MODE=fail
      export BOOTSTRAP_GUM_REPLY=
      ;;
    wrong-host)
      export BOOTSTRAP_GUM_MODE=success
      export BOOTSTRAP_GUM_REPLY='ERASE wrong-host /dev/disk/by-id/nvme-eui.e8238fa6bf530001001b448b47e55428'
      ;;
  esac
  run_capture --host acerus --target root@192.0.2.10 --age-identity "$age_file"
  assert_status 1
  assert_contains "$output" 'Installation cancelled'
  assert_no_install_or_secret_leak "$confirmation_case confirmation"
done

new_case
export BOOTSTRAP_NIX_MODE=success
export BOOTSTRAP_SOPS_MODE=success
export BOOTSTRAP_SSH_MODE=disk
export BOOTSTRAP_GUM_MODE=success
export BOOTSTRAP_GUM_REPLY='ERASE acerus /dev/disk/by-id/nvme-eui.e8238fa6bf530001001b448b47e55428'
export BOOTSTRAP_NIXOS_ANYWHERE_STATUS=0
write_common_stubs
run_capture --host acerus --target root@192.0.2.10 --age-identity "$age_file"
assert_status 0
assert_contains "$output" 'Installation command completed for acerus.'
[[ -e $log_dir/nixos-anywhere ]] || fail 'successful confirmation did not invoke nixos-anywhere'
staging_record=$(<"$log_dir/staging-root")
[[ ! -e $staging_record ]] || fail 'successful installation leaked staging directory'
[[ -d $tmp_dir ]] || fail 'successful cleanup removed TMPDIR parent'
assert_arg_order "$log_dir/nixos-anywhere-args" \
  --flake "$repo_root#acerus-installer" \
  --build-on auto \
  --extra-files "$staging_record" \
  root@192.0.2.10

new_case
export BOOTSTRAP_NIX_MODE=success
export BOOTSTRAP_SOPS_MODE=success
export BOOTSTRAP_SSH_MODE=disk
export BOOTSTRAP_GUM_MODE=success
export BOOTSTRAP_GUM_REPLY='ERASE acerus /dev/disk/by-id/nvme-eui.e8238fa6bf530001001b448b47e55428'
export BOOTSTRAP_NIXOS_ANYWHERE_STATUS=0
write_common_stubs
run_capture --host acerus --target root@192.0.2.10 --age-identity "$age_file" --build-on local
assert_status 0
local_args=$(<"$log_dir/nixos-anywhere-args")
assert_contains "$local_args" '--build-on'
assert_arg_order "$log_dir/nixos-anywhere-args" --build-on local
assert_tmp_clean

new_case
export BOOTSTRAP_NIX_MODE=success
export BOOTSTRAP_SOPS_MODE=success
export BOOTSTRAP_SSH_MODE=disk
export BOOTSTRAP_GUM_MODE=success
export BOOTSTRAP_GUM_REPLY='ERASE acerus /dev/disk/by-id/nvme-eui.e8238fa6bf530001001b448b47e55428'
export BOOTSTRAP_NIXOS_ANYWHERE_STATUS=23
write_common_stubs
run_capture --host acerus --target root@192.0.2.10 --age-identity "$age_file"
assert_status 23
[[ -e $log_dir/nixos-anywhere ]] || fail 'installer failure did not invoke nixos-anywhere'
staging_record=$(<"$log_dir/staging-root")
[[ ! -e $staging_record ]] || fail 'failed installation leaked staging directory'
assert_tmp_clean
[[ -d $tmp_dir ]] || fail 'failed cleanup removed TMPDIR parent'

for signal_name in TERM INT; do
  new_case
  export BOOTSTRAP_NIX_MODE=success
  export BOOTSTRAP_SOPS_MODE=success
  export BOOTSTRAP_SSH_MODE=disk
  export BOOTSTRAP_GUM_MODE=success
  export BOOTSTRAP_GUM_REPLY='ERASE acerus /dev/disk/by-id/nvme-eui.e8238fa6bf530001001b448b47e55428'
  export BOOTSTRAP_NIXOS_ANYWHERE_STATUS=0
  export BOOTSTRAP_NIXOS_ANYWHERE_SIGNAL=$signal_name
  write_common_stubs
  run_capture --host acerus --target root@192.0.2.10 --age-identity "$age_file"
  case $signal_name in
    TERM) assert_status 143 ;;
    INT) assert_status 130 ;;
  esac
  [[ $output != *'Installation command completed'* ]] || fail "$signal_name continued after signal"
  [[ -e $log_dir/nixos-anywhere ]] || fail "$signal_name did not reach staged installer"
  staging_record=$(<"$log_dir/staging-root")
  [[ ! -e $staging_record ]] || fail "$signal_name leaked staging directory"
  assert_tmp_clean
  [[ -d $tmp_dir ]] || fail "$signal_name cleanup removed TMPDIR parent"
done

new_case
export BOOTSTRAP_NIX_MODE=success
export BOOTSTRAP_SOPS_MODE=success
export BOOTSTRAP_SSH_MODE=disk
export BOOTSTRAP_GUM_MODE=success
export BOOTSTRAP_GUM_REPLY='ERASE acerus /dev/disk/by-id/nvme-eui.e8238fa6bf530001001b448b47e55428'
export BOOTSTRAP_NIXOS_ANYWHERE_STATUS=0
write_common_stubs
run_capture --host acerus --target root@192.0.2.10 --age-identity "$age_file" \
  --ssh-auth bootstrap-key --ssh-key "$ssh_key"
assert_status 0
assert_contains "$output" "SSH public key installed: $ssh_key.pub"
mapfile -t bootstrap_events <"$log_dir/events"
[[ ${bootstrap_events[*]} == 'ssh ssh-copy-id ssh gum nixos-anywhere' ]] ||
  fail "unexpected bootstrap event order: ${bootstrap_events[*]}"
bootstrap_copy_args=$(<"$log_dir/ssh-copy-id-args")
assert_contains "$bootstrap_copy_args" "-i $ssh_key.pub"
assert_contains "$bootstrap_copy_args" '-o PreferredAuthentications=password -o PubkeyAuthentication=no root@192.0.2.10'
mapfile -t bootstrap_ssh_calls <"$log_dir/ssh"
[[ ${#bootstrap_ssh_calls[@]} == 2 ]] || fail 'bootstrap-key did not inspect the disk twice'
assert_contains "${bootstrap_ssh_calls[0]}" 'PreferredAuthentications=password'
assert_contains "${bootstrap_ssh_calls[0]}" 'PubkeyAuthentication=no'
assert_contains "${bootstrap_ssh_calls[1]}" 'PreferredAuthentications=publickey'
assert_contains "${bootstrap_ssh_calls[1]}" "-i $ssh_key"
bootstrap_anywhere_args=$(<"$log_dir/nixos-anywhere-args")
assert_contains "$bootstrap_anywhere_args" "IdentityFile=$ssh_key"
assert_contains "$bootstrap_anywhere_args" 'PasswordAuthentication=no'
assert_tmp_clean

new_case
export BOOTSTRAP_NIX_MODE=success
export BOOTSTRAP_SOPS_MODE=success
export BOOTSTRAP_SSH_MODE=disk
write_common_stubs
run_capture --host acerus --target root@192.0.2.10 --age-identity "$age_file" \
  --ssh-auth key --ssh-key "$ssh_key" --preflight
assert_status 0
key_ssh_log=$(<"$log_dir/ssh")
assert_contains "$key_ssh_log" "-o ConnectTimeout=10 -o PreferredAuthentications=publickey -o PasswordAuthentication=no -o IdentitiesOnly=yes -i $ssh_key root@192.0.2.10 bash -s -- /dev/disk/by-id/nvme-eui.e8238fa6bf530001001b448b47e55428"
[[ $key_ssh_log != *'PreferredAuthentications=password'* ]] || fail 'key inspection allowed password authentication'
assert_no_destructive_calls 'key preflight'

new_case
export BOOTSTRAP_NIX_MODE=success
export BOOTSTRAP_SOPS_MODE=success
export BOOTSTRAP_SSH_MODE=disk
write_common_stubs
run_capture --host acerus --target root@192.0.2.10 --age-identity "$age_file" \
  --ssh-auth bootstrap-key --ssh-key "$ssh_key" --preflight
assert_status 0
bootstrap_ssh_log=$(<"$log_dir/ssh")
assert_contains "$bootstrap_ssh_log" '-o ConnectTimeout=10 -o PreferredAuthentications=password -o PubkeyAuthentication=no root@192.0.2.10 bash -s -- /dev/disk/by-id/nvme-eui.e8238fa6bf530001001b448b47e55428'
[[ $bootstrap_ssh_log != *'PreferredAuthentications=publickey'* ]] || fail 'bootstrap-key preflight allowed publickey authentication'
[[ $bootstrap_ssh_log != *' -i '* ]] || fail 'bootstrap-key preflight used a private key'
assert_no_destructive_calls 'bootstrap-key preflight'

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
  '/dev/disk/by-partlabel/disk-btrfs-root' \
  '--tpm2-pcrs=7'; do
  grep -Fq -- "$expected" "$runbook" || fail "runbook missing: $expected"
done

printf 'nixos-installer tests passed\n'

#!/usr/bin/env bash

set -Eeuo pipefail

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
script=${HERDR_PLUGIN_RECONCILE:-$repo_root/modules/shell/herdr-plugin-reconcile.sh}
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

mkdir -p "$tmpdir/bin" "$tmpdir/rename" "$tmpdir/hunk" "$tmpdir/old"
printf 'id = "herdr-automatic-rename"\n' >"$tmpdir/rename/herdr-plugin.toml"
printf 'id = "jhochenbaum.hunkdiff"\n' >"$tmpdir/hunk/herdr-plugin.toml"
printf 'id = "herdr-automatic-rename"\n' >"$tmpdir/old/herdr-plugin.toml"

export HERDR_TEST_REGISTRY="$tmpdir/registry.json"
export HERDR_TEST_INVOCATIONS="$tmpdir/invocations"

mock_bash=${HERDR_TEST_BASH:-$BASH}
[[ $mock_bash == /* && -x $mock_bash ]] || {
  printf 'test requires an absolute executable Bash path: %s\n' "$mock_bash" >&2
  exit 1
}
printf '#!%s\n' "$mock_bash" >"$tmpdir/bin/herdr"
cat >>"$tmpdir/bin/herdr" <<'HERDR'
set -Eeuo pipefail

registry_tmp() { mktemp "$HERDR_TEST_REGISTRY.tmp.XXXXXX"; }

if [[ ${1:-} == plugin && ${2:-} == list && ${3:-} == --json ]]; then
  printf 'list\n' >>"$HERDR_TEST_INVOCATIONS"
  if [[ ${HERDR_TEST_FAIL_LIST:-0} == 1 ]]; then
    printf 'mock list diagnostic\n' >&2
    exit 31
  fi
  cat "$HERDR_TEST_REGISTRY"
  exit 0
fi

if [[ ${1:-} == plugin && ${2:-} == uninstall && $# == 3 ]]; then
  plugin_id=$3
  printf 'uninstall:%s\n' "$plugin_id" >>"$HERDR_TEST_INVOCATIONS"
  if [[ ${HERDR_TEST_FAIL_UNINSTALL:-} == "$plugin_id" ]]; then
    printf 'mock uninstall diagnostic for %s\n' "$plugin_id" >&2
    exit 32
  fi
  output=$(registry_tmp)
  jq --arg id "$plugin_id" \
    '.result.plugins |= map(select(.plugin_id != $id))' \
    "$HERDR_TEST_REGISTRY" >"$output"
  mv -f "$output" "$HERDR_TEST_REGISTRY"
  exit 0
fi

if [[ ${1:-} == plugin && ${2:-} == link && $# == 4 ]]; then
  plugin_root=$3
  link_flag=$4
  printf 'link:%s:%s\n' "$plugin_root" "$link_flag" >>"$HERDR_TEST_INVOCATIONS"
  if [[ ${HERDR_TEST_FAIL_LINK:-} == "$plugin_root" ]]; then
    printf 'mock link diagnostic for %s\n' "$plugin_root" >&2
    exit 33
  fi
  if [[ ${HERDR_TEST_NO_MUTATE_LINK:-0} == 1 ]]; then
    exit 0
  fi
  case $plugin_root in
    "$HERDR_TEST_RENAME_ROOT") plugin_id=herdr-automatic-rename ;;
    "$HERDR_TEST_HUNK_ROOT") plugin_id=jhochenbaum.hunkdiff ;;
    *) printf 'mock link has unknown root\n' >&2; exit 34 ;;
  esac
  case $link_flag in
    --enabled) enabled=true ;;
    --disabled) enabled=false ;;
    *) printf 'mock link has invalid enabled flag\n' >&2; exit 35 ;;
  esac
  output=$(registry_tmp)
  jq --arg id "$plugin_id" \
    --arg manifest "$plugin_root/herdr-plugin.toml" \
    --argjson enabled "$enabled" \
    '.result.plugins |= map(select(.plugin_id != $id))
     | .result.plugins += [{plugin_id: $id, manifest_path: $manifest,
       source: {kind: "local"}, enabled: $enabled}]' \
    "$HERDR_TEST_REGISTRY" >"$output"
  mv -f "$output" "$HERDR_TEST_REGISTRY"
  exit 0
fi

printf 'unexpected herdr invocation: %s\n' "$*" >&2
exit 99
HERDR
chmod +x "$tmpdir/bin/herdr"
export PATH="$tmpdir/bin:$PATH"
export HERDR_BIN="$tmpdir/bin/herdr"
export HERDR_TEST_RENAME_ROOT="$tmpdir/rename"
export HERDR_TEST_HUNK_ROOT="$tmpdir/hunk"

desired="$tmpdir/desired.json"
state="$tmpdir/state/nix-managed-plugins.json"
mkdir -p "$(dirname "$state")"

write_registry() { printf '%s\n' "$1" >"$HERDR_TEST_REGISTRY"; }

write_desired() {
  jq -n --arg rename "$HERDR_TEST_RENAME_ROOT" --arg hunk "$HERDR_TEST_HUNK_ROOT" \
    '{version: 1, plugins: [
      {id: "herdr-automatic-rename", root: $rename, enabled: true},
      {id: "jhochenbaum.hunkdiff", root: $hunk, enabled: true}
    ]}' >"$desired"
}

run_reconcile() {
  bash "$script" --desired-state "$desired" --state-file "$state"
}

reset_case() {
  write_registry '{"result":{"plugins":[]}}'
  : >"$HERDR_TEST_INVOCATIONS"
  rm -f "$state" "$state.lock"
  unset HERDR_TEST_FAIL_LIST HERDR_TEST_FAIL_UNINSTALL HERDR_TEST_FAIL_LINK \
    HERDR_TEST_NO_MUTATE_LINK
  write_desired
}

assert_state_ids() {
  jq -e --argjson expected "$1" '.version == 1 and .plugins == $expected' "$state" >/dev/null
}

assert_registry_ids() {
  jq -e --argjson expected "$1" \
    '([.result.plugins[].plugin_id] | sort) == ($expected | sort)' \
    "$HERDR_TEST_REGISTRY" >/dev/null
}

assert_no_mutations() { ! grep -Eq '^(uninstall|link):' "$HERDR_TEST_INVOCATIONS"; }

run_expect_failure() {
  if run_reconcile >"$tmpdir/stdout" 2>"$tmpdir/stderr"; then
    printf 'expected reconciliation failure\n' >&2
    exit 1
  fi
}

# Empty registry links both desired plugins and writes sorted ownership.
reset_case
run_reconcile
grep -Fx "link:$HERDR_TEST_RENAME_ROOT:--enabled" "$HERDR_TEST_INVOCATIONS"
grep -Fx "link:$HERDR_TEST_HUNK_ROOT:--enabled" "$HERDR_TEST_INVOCATIONS"
assert_state_ids '["herdr-automatic-rename","jhochenbaum.hunkdiff"]'
assert_registry_ids '["herdr-automatic-rename","jhochenbaum.hunkdiff"]'

# A second identical run performs no uninstall or link.
: >"$HERDR_TEST_INVOCATIONS"
run_reconcile
assert_no_mutations
assert_state_ids '["herdr-automatic-rename","jhochenbaum.hunkdiff"]'

# An old local Automatic Rename path is replaced by the current store path.
reset_case
write_registry "$(jq -n --arg root "$tmpdir/old" \
  '{result:{plugins:[{plugin_id:"herdr-automatic-rename",
    manifest_path:($root+"/herdr-plugin.toml"), source:{kind:"local"}, enabled:true}]}}')"
printf '%s\n' '{"version":1,"plugins":["herdr-automatic-rename"]}' >"$state"
run_reconcile
grep -Fx 'uninstall:herdr-automatic-rename' "$HERDR_TEST_INVOCATIONS"
grep -Fx "link:$HERDR_TEST_RENAME_ROOT:--enabled" "$HERDR_TEST_INVOCATIONS"

# A GitHub-managed Hunk Diff entry is uninstalled before local linking.
reset_case
write_registry '{"result":{"plugins":[{"plugin_id":"jhochenbaum.hunkdiff",
  "manifest_path":"/home/user/.local/share/herdr/plugins/hunk/herdr-plugin.toml",
  "source":{"kind":"github","owner":"jhochenbaum","repo":"herdr-hunk-diff"},
  "enabled":true}]}}'
printf '%s\n' '{"version":1,"plugins":["jhochenbaum.hunkdiff"]}' >"$state"
run_reconcile
grep -Fx 'uninstall:jhochenbaum.hunkdiff' "$HERDR_TEST_INVOCATIONS"
grep -Fx "link:$HERDR_TEST_HUNK_ROOT:--enabled" "$HERDR_TEST_INVOCATIONS"

# An enabled-state mismatch is corrected with an explicit --enabled flag.
reset_case
write_registry "$(jq -n --arg root "$HERDR_TEST_RENAME_ROOT" \
  '{result:{plugins:[{plugin_id:"herdr-automatic-rename",
    manifest_path:($root+"/herdr-plugin.toml"), source:{kind:"local"}, enabled:false}]}}')"
run_reconcile
grep -Fx 'uninstall:herdr-automatic-rename' "$HERDR_TEST_INVOCATIONS"
grep -Fx "link:$HERDR_TEST_RENAME_ROOT:--enabled" "$HERDR_TEST_INVOCATIONS"

# Removed managed IDs are pruned while unrelated manual plugins survive.
reset_case
write_registry "$(jq -n --arg root "$HERDR_TEST_RENAME_ROOT" \
  '{result:{plugins:[
    {plugin_id:"herdr-automatic-rename",manifest_path:($root+"/herdr-plugin.toml"),source:{kind:"local"},enabled:true},
    {plugin_id:"jhochenbaum.hunkdiff",manifest_path:"/old/hunk/herdr-plugin.toml",source:{kind:"github"},enabled:true},
    {plugin_id:"manual.plugin",manifest_path:"/manual/herdr-plugin.toml",source:{kind:"local"},enabled:true}]}}')"
printf '%s\n' '{"version":1,"plugins":["herdr-automatic-rename","jhochenbaum.hunkdiff"]}' >"$state"
write_desired
jq 'del(.plugins[] | select(.id == "jhochenbaum.hunkdiff"))' "$desired" >"$tmpdir/desired.new"
mv -f "$tmpdir/desired.new" "$desired"
run_reconcile
grep -Fx 'uninstall:jhochenbaum.hunkdiff' "$HERDR_TEST_INVOCATIONS"
! grep -Fx 'uninstall:manual.plugin' "$HERDR_TEST_INVOCATIONS"
assert_registry_ids '["herdr-automatic-rename","manual.plugin"]'
assert_state_ids '["herdr-automatic-rename"]'

# A same-ID manual plugin is replaced and becomes Nix-managed.
reset_case
write_registry '{"result":{"plugins":[{"plugin_id":"herdr-automatic-rename",
  "manifest_path":"/manual/herdr-plugin.toml", "source":{"kind":"github"}, "enabled":true}]}}'
write_desired
jq 'del(.plugins[] | select(.id == "jhochenbaum.hunkdiff"))' "$desired" >"$tmpdir/desired.new"
mv -f "$tmpdir/desired.new" "$desired"
run_reconcile
grep -Fx 'uninstall:herdr-automatic-rename' "$HERDR_TEST_INVOCATIONS"
assert_state_ids '["herdr-automatic-rename"]'

# Duplicate IDs, invalid schema, relative roots, and missing manifests fail
# before registry mutation.
for invalid in duplicate version relative missing-manifest; do
  reset_case
  case $invalid in
    duplicate) jq '.plugins += [.plugins[0]]' "$desired" >"$tmpdir/desired.new" ;;
    version) jq '.version = 2' "$desired" >"$tmpdir/desired.new" ;;
    relative) jq '.plugins[0].root = "relative/plugin"' "$desired" >"$tmpdir/desired.new" ;;
    missing-manifest) jq '.plugins[0].root = "/does/not/exist"' "$desired" >"$tmpdir/desired.new" ;;
  esac
  mv -f "$tmpdir/desired.new" "$desired"
  run_expect_failure
  ! grep -Fx 'list' "$HERDR_TEST_INVOCATIONS"
  assert_no_mutations
  [[ ! -e $state ]]
done

# A malformed ownership file is fail-closed because it defines the only IDs
# the reconciler is allowed to prune.
reset_case
printf '%s\n' '{"version":1,"plugins":["duplicate","duplicate"]}' >"$state"
run_expect_failure
! grep -Fx 'list' "$HERDR_TEST_INVOCATIONS"
assert_no_mutations
[[ $(<"$state") == '{"version":1,"plugins":["duplicate","duplicate"]}' ]]

# Omitting --state-file follows XDG_STATE_HOME/HOME deterministically, and
# fails instead of accidentally targeting /.local/state when both are absent.
reset_case
default_home="$tmpdir/default-home"
HOME="$default_home" XDG_STATE_HOME= bash "$script" --desired-state "$desired"
jq -e '.version == 1' "$default_home/.local/state/herdr/nix-managed-plugins.json" >/dev/null
if env -u HOME -u XDG_STATE_HOME bash "$script" --desired-state "$desired" \
  >"$tmpdir/stdout" 2>"$tmpdir/stderr"; then
  printf 'expected missing state-home failure\n' >&2
  exit 1
fi
grep -Fq 'neither XDG_STATE_HOME nor HOME is set' "$tmpdir/stderr"

# List, uninstall, link, and post-link verification failures preserve state
# and retain the original Herdr diagnostics.
reset_case
printf '%s\n' '{"version":1,"plugins":["herdr-automatic-rename"]}' >"$state"
export HERDR_TEST_FAIL_LIST=1
run_expect_failure
grep -Fq 'mock list diagnostic' "$tmpdir/stderr"
[[ $(<"$state") == '{"version":1,"plugins":["herdr-automatic-rename"]}' ]]
unset HERDR_TEST_FAIL_LIST

reset_case
write_registry "$(jq -n --arg root "$tmpdir/old" \
  '{result:{plugins:[{plugin_id:"herdr-automatic-rename",manifest_path:($root+"/herdr-plugin.toml"),source:{kind:"local"},enabled:true}]}}')"
printf '%s\n' '{"version":1,"plugins":["herdr-automatic-rename"]}' >"$state"
export HERDR_TEST_FAIL_UNINSTALL=herdr-automatic-rename
run_expect_failure
grep -Fq 'mock uninstall diagnostic' "$tmpdir/stderr"
[[ $(<"$state") == '{"version":1,"plugins":["herdr-automatic-rename"]}' ]]
unset HERDR_TEST_FAIL_UNINSTALL

reset_case
export HERDR_TEST_FAIL_LINK="$HERDR_TEST_RENAME_ROOT"
run_expect_failure
grep -Fq 'mock link diagnostic' "$tmpdir/stderr"
[[ ! -e $state ]]
unset HERDR_TEST_FAIL_LINK

reset_case
export HERDR_TEST_NO_MUTATE_LINK=1
run_expect_failure
grep -Fq 'is not converged' "$tmpdir/stderr"
[[ ! -e $state ]]
unset HERDR_TEST_NO_MUTATE_LINK

# A partial successful migration is idempotently completed on retry.
reset_case
export HERDR_TEST_FAIL_LINK="$HERDR_TEST_HUNK_ROOT"
run_expect_failure
grep -Fx "link:$HERDR_TEST_RENAME_ROOT:--enabled" "$HERDR_TEST_INVOCATIONS"
unset HERDR_TEST_FAIL_LINK
: >"$HERDR_TEST_INVOCATIONS"
run_reconcile
! grep -Fx "link:$HERDR_TEST_RENAME_ROOT:--enabled" "$HERDR_TEST_INVOCATIONS"
grep -Fx "link:$HERDR_TEST_HUNK_ROOT:--enabled" "$HERDR_TEST_INVOCATIONS"
assert_state_ids '["herdr-automatic-rename","jhochenbaum.hunkdiff"]'

# Active and ownerless locks fail; a dead-PID lock is recovered.
reset_case
mkdir "$state.lock"
printf '%s\n' "$$" >"$state.lock/pid"
run_expect_failure
! grep -Fx 'list' "$HERDR_TEST_INVOCATIONS"
rm -f "$state.lock/pid"
rmdir "$state.lock"

reset_case
mkdir "$state.lock"
run_expect_failure
! grep -Fx 'list' "$HERDR_TEST_INVOCATIONS"
rmdir "$state.lock"

reset_case
mkdir "$state.lock"
printf '%s\n' 99999999 >"$state.lock/pid"
run_reconcile
assert_state_ids '["herdr-automatic-rename","jhochenbaum.hunkdiff"]'
[[ ! -e $state.lock ]]

printf 'herdr-plugin-reconcile tests passed\n'

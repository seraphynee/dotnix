#!/usr/bin/env bash

set -Eeuo pipefail

usage() {
  printf 'usage: herdr-plugin-reconcile --desired-state FILE [--state-file FILE]\n' >&2
}

die() {
  printf 'herdr-plugin-reconcile: %s\n' "$*" >&2
  exit 1
}

desired_state=
state_file=
herdr_bin=${HERDR_BIN:-herdr}
while (( $# > 0 )); do
  case $1 in
    --desired-state)
      (( $# >= 2 )) || { usage; exit 2; }
      desired_state=$2
      shift 2
      ;;
    --state-file)
      (( $# >= 2 )) || { usage; exit 2; }
      state_file=$2
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      usage
      exit 2
      ;;
  esac
done

[[ -n $desired_state ]] || { usage; exit 2; }
if [[ -z $state_file ]]; then
  if [[ -n ${XDG_STATE_HOME:-} ]]; then
    state_home=$XDG_STATE_HOME
  elif [[ -n ${HOME:-} ]]; then
    state_home=$HOME/.local/state
  else
    die 'state file was omitted and neither XDG_STATE_HOME nor HOME is set'
  fi
  state_file=$state_home/herdr/nix-managed-plugins.json
fi
[[ -r $desired_state && -f $desired_state ]] || die "desired state is not a readable file: $desired_state"
[[ $state_file == /* ]] || die "state file must be an absolute path: $state_file"

# Validate the store-provided declaration before touching Herdr.  In
# particular, do not let jq's permissive null handling turn malformed input
# into an empty desired set.
if ! jq -e '
  type == "object"
  and .version == 1
  and (.plugins | type == "array")
  and all(.plugins[];
    (.id | type == "string") and (.id | length > 0)
    and (.root | type == "string") and (.root | startswith("/"))
    and (.enabled | type == "boolean")
  )
  and (([.plugins[].id] | length) == ([.plugins[].id] | unique | length))
' "$desired_state" >/dev/null; then
  die "invalid desired state: $desired_state"
fi

# Verify every manifest independently.  A path in the desired JSON is not
# trusted merely because it is absolute: Herdr link requires a real manifest.
mapfile -t desired_entries < <(jq -c '.plugins[]' "$desired_state")
for desired_entry in "${desired_entries[@]}"; do
  plugin_id=$(jq -r '.id' <<<"$desired_entry")
  plugin_root=$(jq -r '.root' <<<"$desired_entry")
  plugin_manifest=${plugin_root%/}/herdr-plugin.toml
  [[ -r $plugin_manifest && -f $plugin_manifest ]] || \
    die "plugin $plugin_id has no readable manifest: $plugin_manifest"
done

state_dir=${state_file%/*}
[[ -n $state_dir && $state_dir != "$state_file" ]] || die "state file has no parent directory: $state_file"
if ! mkdir -p "$state_dir"; then
  die "could not create state directory: $state_dir"
fi

work_dir=$(mktemp -d "${TMPDIR:-/tmp}/herdr-plugin-reconcile.XXXXXX") || \
  die 'could not create a temporary directory'
state_tmp=
lock_path=$state_file.lock
lock_owned=0

cleanup() {
  local status=$?
  trap - EXIT

  if [[ -n ${state_tmp:-} && -e $state_tmp ]]; then
    rm -f -- "$state_tmp"
  fi
  if [[ ${lock_owned:-0} -eq 1 && -d $lock_path && ! -L $lock_path ]]; then
    local owner_pid=
    [[ -r $lock_path/pid ]] && owner_pid=$(<"$lock_path/pid")
    if [[ $owner_pid == "$$" ]]; then
      rm -f -- "$lock_path/pid"
      rmdir -- "$lock_path" 2>/dev/null || true
    fi
  fi
  if [[ -n ${work_dir:-} && -d $work_dir ]]; then
    rm -rf -- "$work_dir"
  fi
  exit "$status"
}
trap cleanup EXIT
trap 'exit 130' HUP INT TERM

acquire_lock() {
  local owner_pid quarantine quarantine_pid

  if mkdir -- "$lock_path" 2>/dev/null; then
    if ! printf '%s\n' "$$" >"$lock_path/pid"; then
      rmdir -- "$lock_path" 2>/dev/null || true
      die "could not publish lock owner: $lock_path"
    fi
    lock_owned=1
    return 0
  fi

  # Never follow or remove an unexpected lock file/symlink.  A lock directory
  # with no numeric owner is also fatal: it may be between mkdir and PID
  # publication in another process.
  [[ -d $lock_path && ! -L $lock_path ]] || die "lock is not a directory: $lock_path"
  owner_pid=
  [[ -r $lock_path/pid ]] && owner_pid=$(<"$lock_path/pid")
  [[ $owner_pid =~ ^[0-9]+$ ]] || die "lock has no numeric owner: $lock_path"
  if kill -0 "$owner_pid" 2>/dev/null; then
    die "lock is held by active PID $owner_pid: $lock_path"
  fi

  # Rename before inspecting/removing a dead lock, so a concurrent invocation
  # cannot mistake a half-recovered directory for an available lock.
  quarantine=$lock_path.recovery.$$.$RANDOM
  if ! mv -- "$lock_path" "$quarantine"; then
    die "could not recover stale lock: $lock_path"
  fi
  quarantine_pid=
  [[ -r $quarantine/pid ]] && quarantine_pid=$(<"$quarantine/pid")
  if [[ $quarantine_pid =~ ^[0-9]+$ ]] && kill -0 "$quarantine_pid" 2>/dev/null; then
    mv -- "$quarantine" "$lock_path" 2>/dev/null || true
    die "lock became active during recovery (PID $quarantine_pid): $lock_path"
  fi
  rm -f -- "$quarantine/pid"
  rmdir -- "$quarantine" 2>/dev/null || die "stale lock is not empty: $lock_path"

  if mkdir -- "$lock_path" 2>/dev/null; then
    if ! printf '%s\n' "$$" >"$lock_path/pid"; then
      rmdir -- "$lock_path" 2>/dev/null || true
      die "could not publish lock owner: $lock_path"
    fi
    lock_owned=1
    return 0
  fi
  die "could not acquire lock: $lock_path"
}

acquire_lock

# Read ownership only after acquiring the lock.  Otherwise a concurrent
# activation could commit a newer ownership set between our read and lock
# acquisition, causing this invocation to prune from stale information.
# The file is deliberately strict because it defines what Nix may remove.
previous_ids_json='[]'
if [[ -e $state_file ]]; then
  [[ -f $state_file && -r $state_file ]] || die "ownership state is not a readable regular file: $state_file"
  if ! jq -e '
    type == "object"
    and ([keys[]] | sort == ["plugins", "version"])
    and .version == 1
    and (.plugins | type == "array")
    and all(.plugins[]; (. | type == "string") and (length > 0))
    and (([.plugins[]] | length) == ([.plugins[]] | unique | length))
    and (.plugins == (.plugins | sort))
  ' "$state_file" >/dev/null; then
    die "invalid ownership state: $state_file"
  fi
  previous_ids_json=$(jq -c '.plugins' "$state_file")
fi

# Capture JSON stdout to a file while allowing Herdr's stderr to remain
# visible.  If Herdr fails, any stdout diagnostic is also surfaced rather than
# being swallowed by command substitution.
list_registry() {
  local output_file=$work_dir/registry.json
  if ! "$herdr_bin" plugin list --json >"$output_file"; then
    cat -- "$output_file" >&2 2>/dev/null || true
    die 'herdr plugin list --json failed'
  fi
  if ! jq -e '
    type == "object"
    and (.result | type == "object")
    and (.result.plugins | type == "array")
  ' "$output_file" >/dev/null; then
    cat -- "$output_file" >&2 2>/dev/null || true
    die 'herdr plugin list --json returned invalid JSON'
  fi
  registry_json=$(<"$output_file")
}

registry_has_id() {
  local plugin_id=$1
  jq -e --arg plugin_id "$plugin_id" \
    '.result.plugins | any(.plugin_id == $plugin_id)' \
    <<<"$registry_json" >/dev/null
}

registry_matches() {
  local plugin_id=$1 plugin_root=$2 plugin_enabled=$3
  local plugin_manifest=${plugin_root%/}/herdr-plugin.toml
  jq -e \
    --arg plugin_id "$plugin_id" \
    --arg plugin_manifest "$plugin_manifest" \
    --argjson plugin_enabled "$plugin_enabled" \
    '.result.plugins | any(
      (.plugin_id == $plugin_id)
      and (.manifest_path == $plugin_manifest)
      and (.source.kind == "local")
      and ((.enabled | type) == "boolean")
      and (.enabled == $plugin_enabled)
    )' <<<"$registry_json" >/dev/null
}

list_registry

# Desired entries are converged first.  A mismatched same-ID entry is always
# uninstalled, including one that was installed manually; declarations win.
for desired_entry in "${desired_entries[@]}"; do
  plugin_id=$(jq -r '.id' <<<"$desired_entry")
  plugin_root=$(jq -r '.root' <<<"$desired_entry")
  plugin_enabled=$(jq -r '.enabled' <<<"$desired_entry")

  if registry_matches "$plugin_id" "$plugin_root" "$plugin_enabled"; then
    continue
  fi

  if registry_has_id "$plugin_id"; then
    if ! "$herdr_bin" plugin uninstall "$plugin_id"; then
      die "herdr plugin uninstall $plugin_id failed"
    fi
  fi

  if [[ $plugin_enabled == true ]]; then
    link_flag=--enabled
  else
    link_flag=--disabled
  fi
  if ! "$herdr_bin" plugin link "$plugin_root" "$link_flag"; then
    die "herdr plugin link $plugin_root $link_flag failed"
  fi
done

desired_ids_json=$(jq -c '[.plugins[].id] | sort' "$desired_state")
# Only IDs recorded as Nix-managed in the previous successful activation are
# eligible for pruning.  This preserves unrelated manual installations.
mapfile -t previous_ids < <(jq -r '.[]' <<<"$previous_ids_json")
for plugin_id in "${previous_ids[@]}"; do
  if jq -e --arg plugin_id "$plugin_id" 'index($plugin_id) == null' <<<"$desired_ids_json" >/dev/null \
    && registry_has_id "$plugin_id"; then
    if ! "$herdr_bin" plugin uninstall "$plugin_id"; then
      die "herdr plugin uninstall $plugin_id failed"
    fi
  fi
done

# This single post-mutation listing verifies every link/uninstall.  It also
# makes a successful command that failed to mutate Herdr visible before state
# ownership is committed.
list_registry
for desired_entry in "${desired_entries[@]}"; do
  plugin_id=$(jq -r '.id' <<<"$desired_entry")
  plugin_root=$(jq -r '.root' <<<"$desired_entry")
  plugin_enabled=$(jq -r '.enabled' <<<"$desired_entry")
  registry_matches "$plugin_id" "$plugin_root" "$plugin_enabled" || \
    die "desired plugin $plugin_id is not converged"
done
for plugin_id in "${previous_ids[@]}"; do
  if jq -e --arg plugin_id "$plugin_id" 'index($plugin_id) == null' <<<"$desired_ids_json" >/dev/null; then
    registry_has_id "$plugin_id" && die "managed plugin $plugin_id was not removed"
  fi
done

# Ownership is committed only after all registry checks pass.  mktemp and mv
# use the same directory, making the replacement atomic to other activations.
state_tmp=$(mktemp "$state_dir/.nix-managed-plugins.XXXXXX") || \
  die "could not create temporary ownership state"
if ! jq -n --argjson ids "$desired_ids_json" \
  '{version: 1, plugins: $ids}' >"$state_tmp"; then
  die 'could not write temporary ownership state'
fi
if ! mv -f -- "$state_tmp" "$state_file"; then
  die "could not atomically replace ownership state: $state_file"
fi
state_tmp=

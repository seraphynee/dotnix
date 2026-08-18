set -u

usage() {
  printf 'usage: herdr-plugin-bootstrap --github PLUGIN_ID OWNER/REPO [...]\n' >&2
}

github_ids=()
github_sources=()

while (( $# > 0 )); do
  case $1 in
    --github)
      (( $# >= 3 )) || { usage; exit 2; }
      plugin_source=$3
      plugin_owner=${plugin_source%%/*}
      plugin_repo=${plugin_source#*/}
      if [[ $plugin_source != */* || -z $plugin_owner || -z $plugin_repo || $plugin_repo == */* ]]; then
        usage
        exit 2
      fi
      github_ids+=("$2")
      github_sources+=("$plugin_source")
      shift 3
      ;;
    *)
      usage
      exit 2
      ;;
  esac
done

if (( ${#github_ids[@]} == 0 )); then
  usage
  exit 2
fi

if [[ -z ${HERDR_SOCKET_PATH:-} ]]; then
  exit 0
fi

lock_dir=${HERDR_PLUGIN_BOOTSTRAP_LOCK_DIR:-${XDG_RUNTIME_DIR:-${TMPDIR:-/tmp}}/herdr-plugin-bootstrap-${UID:-$(id -u)}.lock}

cleanup_lock_candidates() {
  local candidate
  for candidate in "$lock_dir.$$".*; do
    [[ -d $candidate ]] || continue
    rm -f "$candidate/pid"
    rmdir "$candidate" 2>/dev/null || true
  done
}

acquire_lock() {
  local quarantine owner_pid

  if [[ ! -e $lock_dir && ! -L $lock_dir ]]; then
    lock_candidate="$lock_dir.$$.$RANDOM"
    if mkdir "$lock_candidate" 2>/dev/null \
      && printf '%s\n' "$$" > "$lock_candidate/pid" \
      && ln -s "$lock_candidate" "$lock_dir" 2>/dev/null; then
      return 0
    fi
    rm -f "$lock_candidate/pid"
    rmdir "$lock_candidate" 2>/dev/null || true
  fi

  owner_pid=
  if [[ -L $lock_dir ]]; then
    [[ -r $lock_dir/pid ]] && owner_pid=$(<"$lock_dir/pid")
    if [[ $owner_pid =~ ^[0-9]+$ ]] && kill -0 "$owner_pid" 2>/dev/null; then
      return 1
    fi

    quarantine="$lock_dir.recovery.$$.$RANDOM"
    mv "$lock_dir" "$quarantine" 2>/dev/null || return 1
    owner_pid=
    [[ -r $quarantine/pid ]] && owner_pid=$(<"$quarantine/pid")
    if [[ $owner_pid =~ ^[0-9]+$ ]] && kill -0 "$owner_pid" 2>/dev/null; then
      mv "$quarantine" "$lock_dir" 2>/dev/null || true
      return 1
    fi
    rm -f "$quarantine"
    acquire_lock
    return $?
  fi

  if [[ -d $lock_dir ]]; then
    [[ -r $lock_dir/pid ]] && owner_pid=$(<"$lock_dir/pid")
    if [[ $owner_pid =~ ^[0-9]+$ ]] && kill -0 "$owner_pid" 2>/dev/null; then
      return 1
    fi
    [[ $owner_pid =~ ^[0-9]+$ ]] || return 1

    quarantine="$lock_dir.recovery.$$.$RANDOM"
    mv "$lock_dir" "$quarantine" 2>/dev/null || return 1
    owner_pid=
    [[ -r $quarantine/pid ]] && owner_pid=$(<"$quarantine/pid")
    if [[ $owner_pid =~ ^[0-9]+$ ]] && kill -0 "$owner_pid" 2>/dev/null; then
      mv "$quarantine" "$lock_dir" 2>/dev/null || true
      return 1
    fi
    rm -f "$quarantine/pid"
    rmdir "$quarantine" 2>/dev/null || return 1
    acquire_lock
    return $?
  fi

  return 1
}

release_lock() {
  local owner_pid release_link
  owner_pid=
  [[ -r $lock_dir/pid ]] && owner_pid=$(<"$lock_dir/pid")
  if [[ $owner_pid == "$$" && -L $lock_dir ]]; then
    release_link="$lock_dir.release.$$.$RANDOM"
    if mv "$lock_dir" "$release_link" 2>/dev/null; then
      rm -f "$release_link"
    fi
  fi
  cleanup_lock_candidates
}

acquire_lock || exit 0
trap release_lock EXIT HUP INT TERM

owner_pid=
[[ -r $lock_dir/pid ]] && owner_pid=$(<"$lock_dir/pid")
[[ $owner_pid == "$$" ]] || exit 0

if ! plugin_json=$(herdr plugin list --json 2>/dev/null); then
  printf 'herdr: could not inspect plugins; will retry in the next shell\n' >&2
  exit 0
fi

for index in "${!github_ids[@]}"; do
  plugin_id=${github_ids[$index]}
  plugin_source=${github_sources[$index]}
  plugin_owner=${plugin_source%%/*}
  plugin_repo=${plugin_source#*/}

  if jq -e \
    --arg plugin_id "$plugin_id" \
    --arg plugin_owner "$plugin_owner" \
    --arg plugin_repo "$plugin_repo" \
    '.result.plugins // [] | any(
      .plugin_id == $plugin_id
      and .source.kind == "github"
      and .source.owner == $plugin_owner
      and .source.repo == $plugin_repo
    )' >/dev/null <<<"$plugin_json"; then
    continue
  fi

  if ! herdr plugin install "$plugin_source" --yes >/dev/null 2>&1; then
    printf 'herdr: could not install %s; will retry in the next shell\n' \
      "$plugin_source" >&2
  fi
done

exit 0

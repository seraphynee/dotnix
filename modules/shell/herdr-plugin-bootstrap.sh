set -u

usage() {
  printf 'usage: herdr-plugin-bootstrap [--link PLUGIN_ROOT] [--github PLUGIN_ID OWNER/REPO REVISION] ...\n' >&2
}

link_roots=()
github_ids=()
github_sources=()
github_revisions=()

while (( $# > 0 )); do
  case $1 in
    --link)
      (( $# >= 2 )) || { usage; exit 2; }
      link_roots+=("$2")
      shift 2
      ;;
    --github)
      (( $# >= 4 )) || { usage; exit 2; }
      plugin_source=$3
      plugin_owner=${plugin_source%%/*}
      plugin_repo=${plugin_source#*/}
      if [[ $plugin_source != */* || -z $plugin_owner || -z $plugin_repo || $plugin_repo == */* ]]; then
        usage
        exit 2
      fi
      github_ids+=("$2")
      github_sources+=("$plugin_source")
      github_revisions+=("$4")
      shift 4
      ;;
    *)
      usage
      exit 2
      ;;
  esac
done

if (( ${#link_roots[@]} == 0 && ${#github_ids[@]} == 0 )); then
  usage
  exit 2
fi

if [[ -z ${HERDR_SOCKET_PATH:-} ]]; then
  exit 0
fi

lock_dir=${HERDR_PLUGIN_BOOTSTRAP_LOCK_DIR:-${XDG_RUNTIME_DIR:-${TMPDIR:-/tmp}}/herdr-plugin-bootstrap-${UID:-$(id -u)}.lock}

acquire_lock() {
  if mkdir "$lock_dir" 2>/dev/null; then
    printf '%s\n' "$$" > "$lock_dir/pid"
    return 0
  fi

  owner_pid=
  [[ -r $lock_dir/pid ]] && owner_pid=$(<"$lock_dir/pid")
  if [[ $owner_pid =~ ^[0-9]+$ ]] && kill -0 "$owner_pid" 2>/dev/null; then
    return 1
  fi

  rm -f "$lock_dir/pid"
  rmdir "$lock_dir" 2>/dev/null || return 1
  mkdir "$lock_dir" 2>/dev/null || return 1
  printf '%s\n' "$$" > "$lock_dir/pid"
}

release_lock() {
  local owner_pid=
  [[ -r $lock_dir/pid ]] && owner_pid=$(<"$lock_dir/pid")
  if [[ $owner_pid == "$$" ]]; then
    rm -f "$lock_dir/pid"
    rmdir "$lock_dir" 2>/dev/null || true
  fi
}

acquire_lock || exit 0
trap release_lock EXIT HUP INT TERM

if ! plugin_json=$(herdr plugin list --json 2>/dev/null); then
  printf 'herdr: could not inspect plugins; will retry in the next shell\n' >&2
  exit 0
fi

for plugin_root in "${link_roots[@]}"; do
  manifest_path="$plugin_root/herdr-plugin.toml"

  if jq -e --arg manifest_path "$manifest_path" \
    '.result.plugins // [] | any(.manifest_path == $manifest_path)' \
    >/dev/null <<<"$plugin_json"; then
    continue
  fi

  if ! herdr plugin link "$plugin_root" >/dev/null 2>&1; then
    printf 'herdr: could not link %s; will retry in the next shell\n' "$plugin_root" >&2
  fi
done

for index in "${!github_ids[@]}"; do
  plugin_id=${github_ids[$index]}
  plugin_source=${github_sources[$index]}
  plugin_revision=${github_revisions[$index]}
  plugin_owner=${plugin_source%%/*}
  plugin_repo=${plugin_source#*/}

  if jq -e \
    --arg plugin_id "$plugin_id" \
    --arg plugin_owner "$plugin_owner" \
    --arg plugin_repo "$plugin_repo" \
    --arg plugin_revision "$plugin_revision" \
    '.result.plugins // [] | any(
      .plugin_id == $plugin_id
      and .source.kind == "github"
      and .source.owner == $plugin_owner
      and .source.repo == $plugin_repo
      and .source.resolved_commit == $plugin_revision
    )' >/dev/null <<<"$plugin_json"; then
    continue
  fi

  if ! herdr plugin install "$plugin_source" \
    --ref "$plugin_revision" --yes >/dev/null 2>&1; then
    printf 'herdr: could not install %s at %s; will retry in the next shell\n' \
      "$plugin_source" "$plugin_revision" >&2
  fi
done

exit 0

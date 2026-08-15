set -u

if (( $# == 0 )); then
  printf 'usage: herdr-plugin-bootstrap PLUGIN_ROOT [PLUGIN_ROOT ...]\n' >&2
  exit 2
fi

if [[ -z ${HERDR_SOCKET_PATH:-} ]]; then
  exit 0
fi

if ! plugin_json=$(herdr plugin list --json 2>/dev/null); then
  printf 'herdr: could not inspect plugins; will retry in the next shell\n' >&2
  exit 0
fi

for plugin_root in "$@"; do
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

exit 0

set -u

plugin_root=${1:?usage: herdr-plugin-bootstrap PLUGIN_ROOT}
plugin_id=herdr-automatic-rename
manifest_path="$plugin_root/herdr-plugin.toml"

if [[ -z ${HERDR_SOCKET_PATH:-} ]]; then
  exit 0
fi

if ! plugin_json=$(herdr plugin list --plugin "$plugin_id" --json 2>/dev/null); then
  printf 'herdr: could not inspect %s; will retry in the next shell\n' "$plugin_id" >&2
  exit 0
fi

if jq -e --arg plugin_id "$plugin_id" --arg manifest_path "$manifest_path" \
  '.result.plugins // [] | any(.plugin_id == $plugin_id and .manifest_path == $manifest_path)' \
  >/dev/null <<<"$plugin_json"; then
  exit 0
fi

if ! herdr plugin link "$plugin_root" >/dev/null 2>&1; then
  printf 'herdr: could not link %s; will retry in the next shell\n' "$plugin_id" >&2
fi

exit 0

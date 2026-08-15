#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
script="$repo_root/modules/shell/herdr-plugin-bootstrap.sh"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

mkdir -p "$tmpdir/bin" "$tmpdir/plugin-one" "$tmpdir/plugin-two" "$tmpdir/plugin-three"
printf 'id = "plugin.one"\n' > "$tmpdir/plugin-one/herdr-plugin.toml"
printf 'id = "plugin.two"\n' > "$tmpdir/plugin-two/herdr-plugin.toml"
printf 'id = "plugin.three"\n' > "$tmpdir/plugin-three/herdr-plugin.toml"

cat > "$tmpdir/bin/herdr" <<'HERDR'
#!/usr/bin/env bash
set -u

if [[ ${1:-} == plugin && ${2:-} == list ]]; then
  printf 'list\n' >> "$HERDR_TEST_INVOCATIONS"
  if [[ ${HERDR_TEST_FAIL_LIST:-0} == 1 ]]; then
    exit 1
  fi
  cat "$HERDR_TEST_JSON"
  exit 0
fi

if [[ ${1:-} == plugin && ${2:-} == link ]]; then
  printf 'link:%s\n' "$3" >> "$HERDR_TEST_INVOCATIONS"
  if [[ ${HERDR_TEST_FAIL_LINK:-} == "$3" ]]; then
    exit 1
  fi
  exit 0
fi

printf 'unexpected:%s\n' "$*" >&2
exit 99
HERDR
chmod +x "$tmpdir/bin/herdr"

jq -n \
  --arg manifest_path "$tmpdir/plugin-one/herdr-plugin.toml" \
  '{result: {plugins: [{plugin_id: "plugin.one", manifest_path: $manifest_path}]}}' \
  > "$tmpdir/plugins.json"

export PATH="$tmpdir/bin:$PATH"
export HERDR_SOCKET_PATH="$tmpdir/socket"
export HERDR_TEST_JSON="$tmpdir/plugins.json"
export HERDR_TEST_INVOCATIONS="$tmpdir/invocations"

# Existing roots are skipped, while every missing root is linked.
bash "$script" \
  "$tmpdir/plugin-one" \
  "$tmpdir/plugin-two" \
  "$tmpdir/plugin-three"

grep -Fx "list" "$tmpdir/invocations"
grep -Fx "link:$tmpdir/plugin-two" "$tmpdir/invocations"
grep -Fx "link:$tmpdir/plugin-three" "$tmpdir/invocations"
if grep -Fx "link:$tmpdir/plugin-one" "$tmpdir/invocations"; then
  printf 'already-linked plugin was linked again\n' >&2
  exit 1
fi

# A list failure is retryable and must not fail shell startup or link roots.
: > "$tmpdir/invocations"
export HERDR_TEST_FAIL_LIST=1
if ! bash "$script" "$tmpdir/plugin-two"; then
  printf 'plugin-list failure was fatal\n' >&2
  exit 1
fi
if grep -q '^link:' "$tmpdir/invocations"; then
  printf 'plugin-list failure attempted a link\n' >&2
  exit 1
fi
unset HERDR_TEST_FAIL_LIST

# A link failure is retryable and must not prevent the command from returning 0.
: > "$tmpdir/invocations"
export HERDR_TEST_FAIL_LINK="$tmpdir/plugin-three"
if ! bash "$script" "$tmpdir/plugin-two" "$tmpdir/plugin-three"; then
  printf 'plugin-link failure was fatal\n' >&2
  exit 1
fi
grep -Fx "link:$tmpdir/plugin-two" "$tmpdir/invocations"
grep -Fx "link:$tmpdir/plugin-three" "$tmpdir/invocations"
unset HERDR_TEST_FAIL_LINK

# Outside a Herdr pane the script must be a silent no-op.
: > "$tmpdir/invocations"
unset HERDR_SOCKET_PATH
if ! bash "$script" "$tmpdir/plugin-two"; then
  printf 'outside-herdr invocation was fatal\n' >&2
  exit 1
fi
if [[ -s "$tmpdir/invocations" ]]; then
  printf 'outside-herdr invocation called Herdr\n' >&2
  exit 1
fi

printf 'herdr-plugin-bootstrap tests passed\n'

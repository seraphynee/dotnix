#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
script="$repo_root/modules/shell/herdr-plugin-bootstrap.sh"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

mkdir -p "$tmpdir/bin"

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

if [[ ${1:-} == plugin && ${2:-} == install ]]; then
  printf 'install:%s:%s\n' "${3:-}" "${4:-}" >> "$HERDR_TEST_INVOCATIONS"
  if [[ ${HERDR_TEST_FAIL_INSTALL:-0} == 1 ]]; then
    exit 1
  fi
  if [[ ${HERDR_TEST_BLOCK_INSTALL:-0} == 1 ]]; then
    : > "$HERDR_TEST_INSTALL_STARTED"
    while [[ ! -e $HERDR_TEST_INSTALL_RELEASE ]]; do
      sleep 0.02
    done
  fi
  exit 0
fi

printf 'unexpected:%s\n' "$*" >&2
exit 99
HERDR
chmod +x "$tmpdir/bin/herdr"

jq -n '{result: {plugins: []}}' > "$tmpdir/plugins.json"

export PATH="$tmpdir/bin:$PATH"
export HERDR_SOCKET_PATH="$tmpdir/socket"
export HERDR_TEST_JSON="$tmpdir/plugins.json"
export HERDR_TEST_INVOCATIONS="$tmpdir/invocations"

plugin_id="jhochenbaum.hunkdiff"
plugin_source="jhochenbaum/herdr-hunk-diff"
rename_id="herdr-automatic-rename"
rename_source="qu8n/herdr-automatic-rename"
export HERDR_PLUGIN_BOOTSTRAP_LOCK_DIR="$tmpdir/bootstrap.lock"
export HERDR_TEST_INSTALL_STARTED="$tmpdir/install-started"
export HERDR_TEST_INSTALL_RELEASE="$tmpdir/install-release"

# Outside a Herdr pane the script must be a silent no-op.
: > "$tmpdir/invocations"
unset HERDR_SOCKET_PATH
if ! bash "$script" --github "$plugin_id" "$plugin_source"; then
  printf 'outside-herdr invocation was fatal\n' >&2
  exit 1
fi
if [[ -s "$tmpdir/invocations" ]]; then
  printf 'outside-herdr invocation called Herdr\n' >&2
  exit 1
fi
export HERDR_SOCKET_PATH="$tmpdir/socket"

# Missing plugins are installed from GitHub without revision pins.
: > "$tmpdir/invocations"
bash "$script" \
  --github "$rename_id" "$rename_source" \
  --github "$plugin_id" "$plugin_source"
grep -Fx "install:$rename_source:--yes" "$tmpdir/invocations"
grep -Fx "install:$plugin_source:--yes" "$tmpdir/invocations"

bootstrap_args=(--github "$plugin_id" "$plugin_source")

# A list failure is retryable and must not fail shell startup.
: > "$tmpdir/invocations"
export HERDR_TEST_FAIL_LIST=1
if ! bash "$script" "${bootstrap_args[@]}"; then
  printf 'plugin-list failure was fatal\n' >&2
  exit 1
fi
if grep -q '^install:' "$tmpdir/invocations"; then
  printf 'plugin-list failure attempted an install\n' >&2
  exit 1
fi
unset HERDR_TEST_FAIL_LIST

jq -n \
  --arg plugin_id "$plugin_id" \
  '{result: {plugins: [{plugin_id: $plugin_id, source: {
    kind: "github", owner: "jhochenbaum", repo: "herdr-hunk-diff"
  }}]}}' > "$tmpdir/plugins.json"
: > "$tmpdir/invocations"
bash "$script" "${bootstrap_args[@]}"
if grep -q '^install:' "$tmpdir/invocations"; then
  printf 'matching remote plugin was reinstalled\n' >&2
  exit 1
fi

for mismatch_fixture in plugin_id source_kind source_owner source_repo; do
  case $mismatch_fixture in
    plugin_id)
      jq -n \
        '{result: {plugins: [{plugin_id: "other.plugin", source: {
          kind: "github", owner: "jhochenbaum", repo: "herdr-hunk-diff"
        }}]}}' > "$tmpdir/plugins.json"
      ;;
    source_kind)
      jq -n --arg plugin_id "$plugin_id" \
        '{result: {plugins: [{plugin_id: $plugin_id, source: {
          kind: "local", owner: "jhochenbaum", repo: "herdr-hunk-diff"
        }}]}}' > "$tmpdir/plugins.json"
      ;;
    source_owner)
      jq -n --arg plugin_id "$plugin_id" \
        '{result: {plugins: [{plugin_id: $plugin_id, source: {
          kind: "github", owner: "other-owner", repo: "herdr-hunk-diff"
        }}]}}' > "$tmpdir/plugins.json"
      ;;
    source_repo)
      jq -n --arg plugin_id "$plugin_id" \
        '{result: {plugins: [{plugin_id: $plugin_id, source: {
          kind: "github", owner: "jhochenbaum", repo: "other-repo"
        }}]}}' > "$tmpdir/plugins.json"
      ;;
  esac
  : > "$tmpdir/invocations"
  bash "$script" "${bootstrap_args[@]}"
  test "$(grep -Fc "install:$plugin_source:--yes" "$tmpdir/invocations")" -eq 1
done


: > "$tmpdir/invocations"
export HERDR_TEST_FAIL_INSTALL=1
if ! bash "$script" --github "$plugin_id" "$plugin_source"; then
  printf 'remote install failure was fatal\n' >&2
  exit 1
fi
unset HERDR_TEST_FAIL_INSTALL

jq -n '{result: {plugins: []}}' > "$tmpdir/plugins.json"
: > "$tmpdir/invocations"
rm -f "$HERDR_TEST_INSTALL_STARTED" "$HERDR_TEST_INSTALL_RELEASE"
export HERDR_TEST_BLOCK_INSTALL=1
bash "$script" --github "$plugin_id" "$plugin_source" &
first_pid=$!
for _ in {1..100}; do
  [[ -e "$HERDR_TEST_INSTALL_STARTED" ]] && break
  sleep 0.02
done
[[ -e "$HERDR_TEST_INSTALL_STARTED" ]]
bash "$script" --github "$plugin_id" "$plugin_source" &
second_pid=$!
sleep 0.1
test "$(grep -c '^install:' "$tmpdir/invocations")" -eq 1
: > "$HERDR_TEST_INSTALL_RELEASE"
wait "$first_pid"
wait "$second_pid"
test "$(grep -c '^install:' "$tmpdir/invocations")" -eq 1
unset HERDR_TEST_BLOCK_INSTALL

mkdir -p "$HERDR_PLUGIN_BOOTSTRAP_LOCK_DIR"
: > "$tmpdir/invocations"
bash "$script" --github "$plugin_id" "$plugin_source"
if grep -q '^install:' "$tmpdir/invocations"; then
  printf 'unknown lock was reclaimed while ownership was unpublished\n' >&2
  exit 1
fi
rmdir "$HERDR_PLUGIN_BOOTSTRAP_LOCK_DIR"

mkdir -p "$HERDR_PLUGIN_BOOTSTRAP_LOCK_DIR"
printf '99999999\n' > "$HERDR_PLUGIN_BOOTSTRAP_LOCK_DIR/pid"
: > "$tmpdir/invocations"
bash "$script" --github "$plugin_id" "$plugin_source"
grep -Fx "install:$plugin_source:--yes" "$tmpdir/invocations"

printf 'herdr-plugin-bootstrap tests passed\n'

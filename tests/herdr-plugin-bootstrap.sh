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

if [[ ${1:-} == plugin && ${2:-} == install ]]; then
  printf 'install:%s:%s:%s:%s\n' "${3:-}" "${4:-}" "${5:-}" "${6:-}" \
    >> "$HERDR_TEST_INVOCATIONS"
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

jq -n \
  --arg manifest_path "$tmpdir/plugin-one/herdr-plugin.toml" \
  '{result: {plugins: [{plugin_id: "plugin.one", manifest_path: $manifest_path}]}}' \
  > "$tmpdir/plugins.json"

export PATH="$tmpdir/bin:$PATH"
export HERDR_SOCKET_PATH="$tmpdir/socket"
export HERDR_TEST_JSON="$tmpdir/plugins.json"
export HERDR_TEST_INVOCATIONS="$tmpdir/invocations"

plugin_id="jhochenbaum.hunkdiff"
plugin_source="jhochenbaum/herdr-hunk-diff"
plugin_rev="6810ab31b34ec28eb302603846bc4339e7063655"
export HERDR_PLUGIN_BOOTSTRAP_LOCK_DIR="$tmpdir/bootstrap.lock"
export HERDR_TEST_INSTALL_STARTED="$tmpdir/install-started"
export HERDR_TEST_INSTALL_RELEASE="$tmpdir/install-release"

# Existing roots are skipped, while every missing root is linked.
bash "$script" \
  --link "$tmpdir/plugin-one" \
  --link "$tmpdir/plugin-two" \
  --link "$tmpdir/plugin-three"

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
if ! bash "$script" --link "$tmpdir/plugin-two"; then
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
if ! bash "$script" --link "$tmpdir/plugin-two" --link "$tmpdir/plugin-three"; then
  printf 'plugin-link failure was fatal\n' >&2
  exit 1
fi
grep -Fx "link:$tmpdir/plugin-two" "$tmpdir/invocations"
grep -Fx "link:$tmpdir/plugin-three" "$tmpdir/invocations"
unset HERDR_TEST_FAIL_LINK

# Outside a Herdr pane the script must be a silent no-op.
: > "$tmpdir/invocations"
unset HERDR_SOCKET_PATH
if ! bash "$script" --link "$tmpdir/plugin-two"; then
  printf 'outside-herdr invocation was fatal\n' >&2
  exit 1
fi
if [[ -s "$tmpdir/invocations" ]]; then
  printf 'outside-herdr invocation called Herdr\n' >&2
  exit 1
fi
export HERDR_SOCKET_PATH="$tmpdir/socket"

bootstrap_args=(
  --link "$tmpdir/plugin-one"
  --github "$plugin_id" "$plugin_source" "$plugin_rev"
)

jq -n --arg manifest_path "$tmpdir/plugin-one/herdr-plugin.toml" \
  '{result: {plugins: [{plugin_id: "plugin.one", manifest_path: $manifest_path}]}}' \
  > "$tmpdir/plugins.json"
: > "$tmpdir/invocations"
bash "$script" "${bootstrap_args[@]}"
grep -Fx "install:$plugin_source:--ref:$plugin_rev:--yes" "$tmpdir/invocations"

jq -n \
  --arg plugin_id "$plugin_id" \
  --arg rev "$plugin_rev" \
  '{result: {plugins: [{plugin_id: $plugin_id, source: {
    kind: "github", owner: "jhochenbaum", repo: "herdr-hunk-diff",
    resolved_commit: $rev
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
      jq -n --arg rev "$plugin_rev" \
        '{result: {plugins: [{plugin_id: "other.plugin", source: {
          kind: "github", owner: "jhochenbaum", repo: "herdr-hunk-diff",
          resolved_commit: $rev
        }}]}}' > "$tmpdir/plugins.json"
      ;;
    source_kind)
      jq -n --arg plugin_id "$plugin_id" --arg rev "$plugin_rev" \
        '{result: {plugins: [{plugin_id: $plugin_id, source: {
          kind: "local", owner: "jhochenbaum", repo: "herdr-hunk-diff",
          resolved_commit: $rev
        }}]}}' > "$tmpdir/plugins.json"
      ;;
    source_owner)
      jq -n --arg plugin_id "$plugin_id" --arg rev "$plugin_rev" \
        '{result: {plugins: [{plugin_id: $plugin_id, source: {
          kind: "github", owner: "other-owner", repo: "herdr-hunk-diff",
          resolved_commit: $rev
        }}]}}' > "$tmpdir/plugins.json"
      ;;
    source_repo)
      jq -n --arg plugin_id "$plugin_id" --arg rev "$plugin_rev" \
        '{result: {plugins: [{plugin_id: $plugin_id, source: {
          kind: "github", owner: "jhochenbaum", repo: "other-repo",
          resolved_commit: $rev
        }}]}}' > "$tmpdir/plugins.json"
      ;;
  esac
  : > "$tmpdir/invocations"
  bash "$script" "${bootstrap_args[@]}"
  test "$(grep -Fc "install:$plugin_source:--ref:$plugin_rev:--yes" "$tmpdir/invocations")" -eq 1
done

jq -n --arg plugin_id "$plugin_id" \
  '{result: {plugins: [{plugin_id: $plugin_id, source: {
    kind: "github", owner: "jhochenbaum", repo: "herdr-hunk-diff",
    resolved_commit: "old-revision"
  }}]}}' > "$tmpdir/plugins.json"
: > "$tmpdir/invocations"
bash "$script" "${bootstrap_args[@]}"
grep -Fx "install:$plugin_source:--ref:$plugin_rev:--yes" "$tmpdir/invocations"

: > "$tmpdir/invocations"
export HERDR_TEST_FAIL_INSTALL=1
if ! bash "$script" --github "$plugin_id" "$plugin_source" "$plugin_rev"; then
  printf 'remote install failure was fatal\n' >&2
  exit 1
fi
unset HERDR_TEST_FAIL_INSTALL

jq -n '{result: {plugins: []}}' > "$tmpdir/plugins.json"
: > "$tmpdir/invocations"
rm -f "$HERDR_TEST_INSTALL_STARTED" "$HERDR_TEST_INSTALL_RELEASE"
export HERDR_TEST_BLOCK_INSTALL=1
bash "$script" --github "$plugin_id" "$plugin_source" "$plugin_rev" &
first_pid=$!
for _ in {1..100}; do
  [[ -e "$HERDR_TEST_INSTALL_STARTED" ]] && break
  sleep 0.02
done
[[ -e "$HERDR_TEST_INSTALL_STARTED" ]]
bash "$script" --github "$plugin_id" "$plugin_source" "$plugin_rev" &
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
bash "$script" --github "$plugin_id" "$plugin_source" "$plugin_rev"
if grep -q '^install:' "$tmpdir/invocations"; then
  printf 'unknown lock was reclaimed while ownership was unpublished\n' >&2
  exit 1
fi
rmdir "$HERDR_PLUGIN_BOOTSTRAP_LOCK_DIR"

mkdir -p "$HERDR_PLUGIN_BOOTSTRAP_LOCK_DIR"
printf '99999999\n' > "$HERDR_PLUGIN_BOOTSTRAP_LOCK_DIR/pid"
: > "$tmpdir/invocations"
bash "$script" --github "$plugin_id" "$plugin_source" "$plugin_rev"
grep -Fx "install:$plugin_source:--ref:$plugin_rev:--yes" "$tmpdir/invocations"

printf 'herdr-plugin-bootstrap tests passed\n'

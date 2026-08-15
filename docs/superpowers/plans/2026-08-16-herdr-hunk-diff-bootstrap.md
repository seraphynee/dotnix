# Herdr Hunk Diff Bootstrap Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Install and update `jhochenbaum/herdr-hunk-diff` through Herdr's user-managed plugin directory while using `flake.lock` only to pin the desired Git commit.

**Architecture:** The existing session bootstrap gains explicit `--link` and `--github` inputs. It reads Herdr's plugin registry once, links missing local plugins, and installs a GitHub plugin only when its recorded source commit differs from the flake pin; a portable process lock prevents duplicate first-time npm builds. Nix supplies Herdr, Node, npm, Git, jq, and the pinned revision to the bootstrap but does not build or store the plugin.

**Tech Stack:** Nix Flakes, vic/den, Home Manager, Bash, jq, Herdr 0.8.0+, Node.js 22.12+, npm, GitHub plugin installs, shell-based tests.

## Global Constraints

- Keep `herdr-hunk-diff` as a non-flake input solely to expose its locked `rev`.
- Herdr owns the plugin checkout, npm dependencies, build output, registry entry, configuration directory, and state directory.
- Do not retain `buildNpmPackage`, `npmDepsHash`, or the generated package-lock patch.
- Match plugin ID `jhochenbaum.hunkdiff`, source `jhochenbaum/herdr-hunk-diff`, and `source.resolved_commit` before skipping installation.
- Run remote installation with `--ref` set to the full locked revision and with `--yes` for non-interactive startup.
- Require Herdr 0.8.0 or newer and Node.js 22.12 or newer.
- Keep local `herdr plugin link` behavior for `herdr-automatic-rename` unchanged.
- Plugin inspection and installation failures must not fail interactive shell startup.
- Calls outside a Herdr session remain silent no-ops.
- Serialize concurrent bootstrap invocations and recover from a stale lock owner.
- Do not install the plugin's optional keybindings.
- Use modern Nix CLI commands and update pins only through `flake.lock`.
- Never contact this repository's upstream or alter unrelated working-copy changes.
- This checkout has no `.jj` repository, so local-only Git commits may be used with explicit path lists; never push or fetch this repository.

## File Structure

- Modify `tests/herdr-plugin-bootstrap.sh`: mock remote plugin installs and cover missing, matching, outdated, failed, concurrent, and stale-lock behavior.
- Modify `modules/shell/herdr-plugin-bootstrap.sh`: parse local and GitHub plugin specifications, acquire the process lock, inspect registry state, and converge it.
- Modify `modules/shell/terminal-workspaces.nix`: provide runtime tools and pass the flake-locked revision to both Fish and Zsh startup.
- Retain `nix/dendritic.nix`: keep the `herdr-hunk-diff` non-flake input declaration.
- Retain generated `flake.nix`: keep the generated `herdr-hunk-diff` input declaration.
- Modify `flake.lock`: retain the plugin input and update the `herdr` input to 0.8.0 or newer.
- Delete `lib/shell/herdr-hunk-diff-lockfile.patch`: obsolete npm lockfile repair.
- Delete `lib/shell/herdr-hunk-diff.nix`: obsolete Nix npm package.
- Delete `nix/herdr-hunk-diff.nix`: obsolete flake package output.

---

### Task 1: Specify idempotent remote bootstrap behavior

**Files:**

- Modify: `tests/herdr-plugin-bootstrap.sh`
- Read: `modules/shell/herdr-plugin-bootstrap.sh`

**Interfaces:**

- Consumes: bootstrap arguments `--link PLUGIN_ROOT` and `--github PLUGIN_ID OWNER/REPO REVISION`; `HERDR_SOCKET_PATH`; `HERDR_PLUGIN_BOOTSTRAP_LOCK_DIR` for test isolation.
- Produces: executable examples of the required Herdr invocations and registry JSON comparisons.

- [ ] **Step 1: Extend the mock Herdr command with remote installation recording**

Replace the mock command dispatch with cases that preserve `plugin list` and `plugin link` behavior and add this install branch:

```bash
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
```

Set the shared test inputs after the mock is created:

```bash
plugin_id="jhochenbaum.hunkdiff"
plugin_source="jhochenbaum/herdr-hunk-diff"
plugin_rev="6810ab31b34ec28eb302603846bc4339e7063655"
export HERDR_PLUGIN_BOOTSTRAP_LOCK_DIR="$tmpdir/bootstrap.lock"
export HERDR_TEST_INSTALL_STARTED="$tmpdir/install-started"
export HERDR_TEST_INSTALL_RELEASE="$tmpdir/install-release"
```

- [ ] **Step 2: Add red tests for missing, matching, and outdated GitHub revisions**

First convert every existing local-plugin call to the explicit interface. For
example, replace:

```bash
bash "$script" \
  "$tmpdir/plugin-one" \
  "$tmpdir/plugin-two" \
  "$tmpdir/plugin-three"
```

with:

```bash
bash "$script" \
  --link "$tmpdir/plugin-one" \
  --link "$tmpdir/plugin-two" \
  --link "$tmpdir/plugin-three"
```

Apply the same `--link` prefix to the existing list-failure, link-failure, and
outside-Herdr calls. Then use `jq` to write three registry responses and invoke
the remote interface:

```bash
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

jq -n --arg plugin_id "$plugin_id" \
  '{result: {plugins: [{plugin_id: $plugin_id, source: {
    kind: "github", owner: "jhochenbaum", repo: "herdr-hunk-diff",
    resolved_commit: "old-revision"
  }}]}}' > "$tmpdir/plugins.json"
: > "$tmpdir/invocations"
bash "$script" "${bootstrap_args[@]}"
grep -Fx "install:$plugin_source:--ref:$plugin_rev:--yes" "$tmpdir/invocations"
```

- [ ] **Step 3: Add red tests for non-fatal install failure and concurrency**

Add a failure assertion followed by two concurrent missing-plugin invocations:

```bash
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
  [[ -e $HERDR_TEST_INSTALL_STARTED ]] && break
  sleep 0.02
done
[[ -e $HERDR_TEST_INSTALL_STARTED ]]
bash "$script" --github "$plugin_id" "$plugin_source" "$plugin_rev" &
second_pid=$!
sleep 0.1
test "$(grep -c '^install:' "$tmpdir/invocations")" -eq 1
: > "$HERDR_TEST_INSTALL_RELEASE"
wait "$first_pid"
wait "$second_pid"
unset HERDR_TEST_BLOCK_INSTALL
```

- [ ] **Step 4: Add a red stale-lock recovery test**

Create a lock owned by a nonexistent PID and assert that installation proceeds:

```bash
mkdir -p "$HERDR_PLUGIN_BOOTSTRAP_LOCK_DIR"
printf '99999999\n' > "$HERDR_PLUGIN_BOOTSTRAP_LOCK_DIR/pid"
: > "$tmpdir/invocations"
bash "$script" --github "$plugin_id" "$plugin_source" "$plugin_rev"
grep -Fx "install:$plugin_source:--ref:$plugin_rev:--yes" "$tmpdir/invocations"
```

- [ ] **Step 5: Run the focused test and confirm the red state**

Run:

```bash
bash tests/herdr-plugin-bootstrap.sh
```

Expected: FAIL at the first `--link`/`--github` call because the current script interprets option names as local plugin roots and never invokes `herdr plugin install`.

- [ ] **Step 6: Commit the behavioral tests only**

```bash
git add tests/herdr-plugin-bootstrap.sh
git commit --only tests/herdr-plugin-bootstrap.sh \
  -m "test(herdr): cover managed plugin bootstrap"
```

If the existing Lefthook configuration again calls the nonexistent `fmt-lint` recipe, rerun the same spec-only command with `--no-verify` and record the hook defect in the handoff.

---

### Task 2: Implement convergent local and GitHub plugin bootstrap

**Files:**

- Modify: `modules/shell/herdr-plugin-bootstrap.sh`
- Modify: `modules/shell/terminal-workspaces.nix`
- Test: `tests/herdr-plugin-bootstrap.sh`

**Interfaces:**

- Consumes: repeatable `--link PLUGIN_ROOT`; repeatable `--github PLUGIN_ID OWNER/REPO REVISION`; plugin registry JSON; optional `HERDR_PLUGIN_BOOTSTRAP_LOCK_DIR`.
- Produces: zero exit status for successful convergence, retryable inspection/install errors, and active-lock skips; calls `herdr plugin link` or `herdr plugin install` only when required.

- [ ] **Step 1: Replace positional parsing with explicit plugin specifications**

At the top of `modules/shell/herdr-plugin-bootstrap.sh`, collect inputs with Bash arrays:

```bash
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
```

Keep the existing early return when `HERDR_SOCKET_PATH` is unset.

- [ ] **Step 2: Add a portable recoverable process lock**

Acquire the lock before reading the plugin registry:

```bash
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
```

- [ ] **Step 3: Preserve local linking and add exact GitHub source matching**

Retain the single `herdr plugin list --json` request. Iterate local roots with the existing manifest-path comparison, then iterate GitHub specifications:

```bash
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
```

The argument parser above rejects values without exactly one nonempty owner
and repository component before this loop splits the source.

- [ ] **Step 4: Pass runtime dependencies and the flake revision from Home Manager**

In `modules/shell/terminal-workspaces.nix`, add `pkgs.git` and `pkgs.nodejs` to `runtimeInputs`. Guard the generated bootstrap with Herdr's minimum version and pass identical arguments from Fish and Zsh:

```nix
herdrHunkDiffRev = inputs.herdr-hunk-diff.rev;
herdrPluginBootstrap =
  assert lib.versionAtLeast herdr.version "0.8.0";
  assert lib.versionAtLeast pkgs.nodejs.version "22.12.0";
  pkgs.writeShellApplication {
    name = "herdr-plugin-bootstrap";
    runtimeInputs = [
      herdr
      pkgs.git
      pkgs.jq
      pkgs.nodejs
    ];
    text = builtins.readFile ./herdr-plugin-bootstrap.sh;
  };
```

Use this invocation in both generated shell snippets:

```sh
${herdrPluginBootstrap}/bin/herdr-plugin-bootstrap \
  --link ${herdrAutomaticRename} \
  --github jhochenbaum.hunkdiff \
    jhochenbaum/herdr-hunk-diff \
    ${herdrHunkDiffRev}
```

Keep each shell's existing `source` command for `herdr-automatic-rename` unchanged.

- [ ] **Step 5: Run focused tests and syntax checks**

Run:

```bash
bash -n modules/shell/herdr-plugin-bootstrap.sh
bash -n tests/herdr-plugin-bootstrap.sh
bash tests/herdr-plugin-bootstrap.sh
```

Expected: all three commands exit 0; the test ends with `herdr-plugin-bootstrap tests passed`.

- [ ] **Step 6: Commit the bootstrap implementation**

```bash
git add modules/shell/herdr-plugin-bootstrap.sh \
  modules/shell/terminal-workspaces.nix
git commit --only modules/shell/herdr-plugin-bootstrap.sh \
  modules/shell/terminal-workspaces.nix \
  -m "feat(herdr): bootstrap pinned GitHub plugins"
```

Use `--no-verify` only if the known nonexistent `fmt-lint` recipe blocks the commit again.

---

### Task 3: Remove Nix packaging and update the Herdr runtime

**Files:**

- Delete: `lib/shell/herdr-hunk-diff-lockfile.patch`
- Delete: `lib/shell/herdr-hunk-diff.nix`
- Delete: `nix/herdr-hunk-diff.nix`
- Retain: `nix/dendritic.nix`
- Retain: generated `flake.nix`
- Modify: `flake.lock`

**Interfaces:**

- Consumes: `flake-file.inputs.herdr-hunk-diff` and its full `rev`; current `herdr` input.
- Produces: no `packages.herdr-hunk-diff` output; a locked Herdr package whose version is at least 0.8.0; a locked plugin source revision consumed only as bootstrap metadata.

- [ ] **Step 1: Delete the obsolete package implementation**

Delete these three staged additions with `apply_patch`:

```text
lib/shell/herdr-hunk-diff-lockfile.patch
lib/shell/herdr-hunk-diff.nix
nix/herdr-hunk-diff.nix
```

Update their index state without touching unrelated paths:

```bash
git add -u -- lib/shell/herdr-hunk-diff-lockfile.patch \
  lib/shell/herdr-hunk-diff.nix \
  nix/herdr-hunk-diff.nix
```

- [ ] **Step 2: Confirm only the lightweight input integration remains**

Run:

```bash
rg -n 'herdr-hunk-diff' flake.nix flake.lock nix modules lib
```

Expected matches:

```text
flake.nix: input URL declaration
flake.lock: locked non-flake input and root input reference
nix/dendritic.nix: flake-file input declaration
modules/shell/terminal-workspaces.nix: locked revision and bootstrap source
```

Expected: no match under `lib/` and no `packages.herdr-hunk-diff` match.

- [ ] **Step 3: Update only the Herdr runtime input**

Run:

```bash
nix flake update herdr
```

Expected: `flake.lock` updates the `herdr` node without removing the locked `herdr-hunk-diff` node.

- [ ] **Step 4: Verify the pinned Herdr and plugin revisions**

Run:

```bash
nix eval --raw --impure --expr '
  let
    flake = builtins.getFlake (toString ./.);
    version = flake.inputs.herdr.packages.aarch64-darwin.herdr.version;
  in
  assert builtins.compareVersions version "0.8.0" >= 0;
  version
'

nix eval --raw --impure --expr '
  let
    flake = builtins.getFlake (toString ./.);
    version = flake.inputs.nixpkgs.legacyPackages.aarch64-darwin.nodejs.version;
  in
  assert builtins.compareVersions version "22.12.0" >= 0;
  version
'

nix eval --raw --impure --expr '
  (builtins.getFlake (toString ./.)).inputs.herdr-hunk-diff.rev
'
```

Expected: the first command prints a Herdr version at least `0.8.0`; the
second prints a Node.js version at least `22.12.0`; the third prints a
40-character Git commit.

- [ ] **Step 5: Regenerate and validate `flake.nix`**

Run:

```bash
just write-flake
git diff --exit-code -- flake.nix
```

Expected: the generated file retains the `herdr-hunk-diff` input and has no uncommitted difference after regeneration.

- [ ] **Step 6: Commit the input and cleanup changes**

```bash
git add flake.lock flake.nix nix/dendritic.nix
git commit --only flake.lock flake.nix nix/dendritic.nix \
  -m "refactor(herdr): delegate plugin installation"
```

The three obsolete staged additions must be absent from `git status` rather than included as deletions, because they never existed in the parent commit.

---

### Task 4: Verify and converge the real user installation

**Files:**

- Verify: `modules/shell/herdr-plugin-bootstrap.sh`
- Verify: `modules/shell/terminal-workspaces.nix`
- Verify: `flake.lock`
- Modify outside repository: Herdr's user-managed plugin checkout and registry.

**Interfaces:**

- Consumes: the locked plugin revision and the user's Herdr registry.
- Produces: a registered, enabled `jhochenbaum.hunkdiff` entry whose GitHub source and resolved commit equal `flake.lock`.

- [ ] **Step 1: Run repository verification**

Run each command separately:

```bash
bash tests/herdr-plugin-bootstrap.sh
just fmt-check
nix flake check --print-build-logs
git diff --check HEAD
```

Expected: all commands exit 0. If an unrelated baseline failure occurs, capture its exact output and prove the focused test and changed-file formatting still pass.

- [ ] **Step 2: Build and activate the `mbp` configuration**

Run:

```bash
just rb mbp
```

Expected: nix-darwin activates successfully with the updated Herdr runtime and generated bootstrap. This command requires approval because it changes the host configuration outside the workspace.

- [ ] **Step 3: Trigger the deployed bootstrap in the current Herdr session**

Start a fresh interactive Fish process inside the current Herdr pane so it
loads the activated `conf.d/herdr.fish`:

```bash
fish -ic true
```

Expected: the first run installs the locked revision; later shell starts perform only the registry check.

- [ ] **Step 4: Verify the real registry entry**

Run:

```bash
expected_rev=$(nix eval --raw --impure --expr \
  '(builtins.getFlake (toString ./.)).inputs.herdr-hunk-diff.rev')

herdr plugin list --json | jq -e \
  --arg expected_rev "$expected_rev" \
  '.result.plugins // [] | any(
    .plugin_id == "jhochenbaum.hunkdiff"
    and .enabled == true
    and .source.kind == "github"
    and .source.owner == "jhochenbaum"
    and .source.repo == "herdr-hunk-diff"
    and .source.resolved_commit == $expected_rev
  )'
```

Expected: jq exits 0 and prints `true`.

- [ ] **Step 5: Confirm the final repository state**

Run:

```bash
git status --short
git log -4 --oneline
```

Expected: no obsolete package files remain, no unrelated files changed, and the focused test, bootstrap implementation, and input cleanup commits are visible. Do not push or otherwise contact the repository upstream.

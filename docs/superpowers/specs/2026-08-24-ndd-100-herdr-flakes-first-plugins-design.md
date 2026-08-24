# NDD-100 Flakes-First Herdr Plugins Design

## Purpose

Replace Herdr's networked shell-startup plugin installer with a declarative,
flakes-first plugin set. Both `qu8n/herdr-automatic-rename` and
`jhochenbaum/herdr-hunk-diff` must be pinned by `flake.lock`, materialized in
the Nix store, and reconciled into Herdr's mutable registry during Home Manager
activation.

The result must fix the existing `local` to `github` source conflict, remove
Git and npm work from interactive shell startup, support future plugins through
one internal attrset and helper, and prune plugins that were previously managed
by Nix but have since been removed from that attrset.

## Selected Approach

Use one non-flake input per upstream plugin repository, an internal
`herdrPlugins` attrset, and a private `mkHerdrPlugin` helper. A plugin entry has
this normalized shape:

```nix
{
  id = "herdr-automatic-rename";
  root = /nix/store/...;
  enabled = true;
  hooks = {
    fish = "shell/hook.fish";
    zsh = "shell/hook.zsh";
  };
}
```

`root` may be the pinned source itself or a derivation produced by a custom
builder. The helper accepts `id`, `src`, optional `builder`, `enabled` defaulting
to `true`, and optional Fish/Zsh hook paths. It returns the normalized shape;
consumers do not distinguish source-only and built plugins.

Keep this registry internal rather than adding a public Home Manager option.
The first implementation manages both existing plugins. A flake aggregator is
out of scope; it becomes worthwhile only if the collection is reused outside
this repository.

Implementation placement is fixed as follows:

- `lib/shell/herdr-plugins.nix` owns `mkHerdrPlugin`, the internal attrset, and
  the Hunk Diff derivation.
- `modules/shell/terminal-multiplexer.nix` consumes the normalized attrset,
  declares Home Manager activation, and generates deterministic Fish/Zsh hook
  configuration.
- Rename `modules/shell/herdr-plugin-bootstrap.sh` to
  `modules/shell/herdr-plugin-reconcile.sh`; likewise replace the existing
  bootstrap test with `tests/herdr-plugin-reconcile.sh`.
- Add a flake-parts check module under `nix/checks/` that imports the same
  helper, builds Hunk Diff, and executes the packaged reconciler tests.

## Flake and Packaging Model

Declare `herdr-automatic-rename` and `herdr-hunk-diff` under
`flake-file.inputs` in `nix/dendritic.nix`, both with `flake = false`. Regenerate
the generated `flake.nix` through `nix run .#write-flake` and update
`flake.lock`; never edit generated input declarations by hand.

`herdr-automatic-rename` is a source-only shell plugin. Its plugin root is the
non-flake input path directly, with deterministic Fish and Zsh hooks under
`shell/`.

`herdr-hunk-diff` must be built as a Nix derivation because its manifest
declares `npm ci` and `npm run build`, and `herdr plugin link` intentionally
does not run those build commands. The derivation must:

- Require Node.js 22.12 or newer.
- Compile the pinned TypeScript source with Nixpkgs' TypeScript compiler. Use
  `--noCheck`: upstream owns type-checking, while this build only needs the
  deterministic JavaScript emission and therefore does not need its development
  dependency graph.
- Fetch the only JavaScript runtime library, `smol-toml`, directly as a
  fixed-output npm tarball with its SHA-512 integrity hash.
- Fetch only the pinned `hunkdiff` wrapper and the matching Linux/Darwin
  platform binary as fixed-output npm tarballs. This preserves the plugin's
  verified Hunk 0.18.1 runtime without resolving the package's unrelated npm
  dependency graph.
- Install `herdr-plugin.toml`, `package.json`, `dist`, the runtime library, and
  Hunk link, and retain Node in the Home Manager package environment because
  the manifest invokes `node` by name.

The upstream Hunk Diff `package-lock.json` cannot be consumed directly by
either `importNpmLock` or `buildNpmPackage`: a number of entries, including
`zwitch`, omit `resolved` and `integrity`, causing offline cache misses.
Do not repair that incomplete lockfile during activation or depend on npm's
mutable dependency resolution. The minimal Nix-native runtime closure above
avoids the incomplete lockfile entirely while pinning every required source.

Expose the built Hunk Diff derivation as a flake check so CI proves that its
source, compilation, fixed-output runtime libraries, Hunk executable, manifest,
and entrypoints are all available offline after fetching fixed outputs.

## Registry Reconciliation

Replace the shell-startup bootstrap with a packaged
`herdr-plugin-reconcile` command invoked by
`home.activation.herdrPlugins` after `linkGeneration`. Its runtime closure
contains the pinned Herdr CLI, Bash, jq, and coreutils. It has no Git, npm, or
network operation.

Nix writes a desired-state JSON file in the store:

```json
{
  "version": 1,
  "plugins": [
    {
      "id": "herdr-automatic-rename",
      "root": "/nix/store/...",
      "enabled": true
    }
  ]
}
```

The reconciler owns a mutable state file at
`$XDG_STATE_HOME/herdr/nix-managed-plugins.json`, falling back to the standard
Home Manager state home. It stores only schema version and the sorted plugin
IDs successfully managed by the previous activation. Write it through a
same-directory temporary file and atomic rename only after full convergence.

Reconciliation runs in this order:

1. Validate schema version, unique non-empty IDs, boolean enabled values,
   absolute plugin roots, and readable `herdr-plugin.toml` files.
2. Acquire a portable process lock adjacent to the state file. Recover a lock
   only when it contains a numeric PID that is no longer alive; an active or
   ownerless lock is fatal rather than silently skipping declarative work.
3. Read Herdr's registry once with `herdr plugin list --json`. Herdr's offline
   registry fallback makes this valid whether or not a server is running.
4. For every desired plugin, treat it as converged only when plugin ID,
   manifest path, `source.kind = "local"`, and enabled state all match. Otherwise
   uninstall the existing ID when present, link the desired root with explicit
   `--enabled` or `--disabled`, and verify the resulting registry entry.
5. Compare the previous Nix-managed ID set with the desired set. For each
   removed ID still present in Herdr, run `herdr plugin uninstall ID` and verify
   removal. `uninstall` is required instead of `unlink` because it supports
   offline registry mutation and safely removes an old Herdr-managed GitHub
   checkout while never deleting a local Nix store path.
6. Re-list and verify every desired entry and every removed managed ID, then
   atomically replace the ownership state file.

Any validation, list, uninstall, link, or verification failure exits nonzero,
prints the original Herdr diagnostic, leaves the ownership state file
unchanged, and fails Home Manager activation. A later activation is safe to
retry after partial registry progress.

Nix owns plugin IDs recorded in the ownership file. An unrelated manually
installed plugin is preserved. A manually installed plugin with the same ID as
a desired entry is deliberately replaced by the Nix declaration; an ID removed
from the declaration is uninstalled even if it was manually reinstalled in the
meantime.

## Shell Integration and Migration

Fish and Zsh startup must no longer invoke a plugin bootstrap command. They
source the Automatic Rename hook directly from its pinned Nix plugin root.
Hunk Diff has no shell hook.

The first activation performs both required migrations automatically:

- The existing Automatic Rename entry linked from an older Nix store path is
  uninstalled from the registry and linked to the current pinned source.
- The existing Hunk Diff GitHub checkout is uninstalled, including only its
  Herdr-managed checkout files, and replaced by the locally built Nix output.

Plugin configuration and state directories remain untouched. After successful
activation, opening Fish or Zsh performs no registry inspection, Git fetch,
npm install, TypeScript build, or plugin migration.

## Automated Tests

Replace the current bootstrap test with focused reconciler tests using a mock
Herdr CLI and isolated desired/state/registry fixtures. Cover at least:

- Empty registry links both desired plugins and writes sorted ownership state.
- A second identical run performs no uninstall or link.
- An old local Automatic Rename path is replaced by the desired Nix path.
- A GitHub-managed Hunk Diff entry is uninstalled before the local Nix link.
- An enabled-state mismatch is corrected.
- A formerly managed plugin removed from desired state is uninstalled.
- An unrelated manually installed plugin is preserved.
- A same-ID manual plugin is replaced and becomes Nix-managed.
- Duplicate IDs, invalid schema, relative roots, and missing manifests fail
  before registry mutation.
- List, uninstall, link, and post-link verification failures return nonzero and
  do not update ownership state.
- A partial successful migration is idempotently completed on retry.
- Active and ownerless locks fail; a dead-PID lock is recovered.

Add flake checks that run the shell suite against the packaged reconciler and
build the Hunk Diff derivation. Final verification is:

```bash
bash -n modules/shell/herdr-plugin-reconcile.sh
bash -n tests/herdr-plugin-reconcile.sh
bash tests/herdr-plugin-reconcile.sh
nix run .#write-flake
nix fmt -- --ci
nix flake check --print-build-logs
```

After applying the Home Manager configuration, acceptance additionally
requires `herdr plugin list --json` to show both IDs as enabled local plugins
whose manifest paths are under `/nix/store`, no managed GitHub checkout for
either plugin, and no Herdr installation command during Fish or Zsh startup.

## Update Workflow

Update one plugin with the modern Nix CLI:

```bash
nix flake update herdr-automatic-rename
nix flake update herdr-hunk-diff
```

Automatic Rename needs only evaluation and checks. A Hunk Diff update must
review changes to its runtime imports, fixed-output npm versions/integrities,
its minimum Node version, and verified Hunk version, then pass
the package and reconciler checks. Home activation links the new store path;
rollback links the previous generation's store path without contacting GitHub
or npm.

## Out of Scope

- A public `dotnix.herdr.plugins` Home Manager option.
- A standalone Herdr plugin aggregator flake.
- Runtime auto-update or tracking an unpinned GitHub branch.
- Managing plugin-specific user configuration, keybindings, or runtime state.
- Removing manually installed plugins that were never recorded as Nix-managed.

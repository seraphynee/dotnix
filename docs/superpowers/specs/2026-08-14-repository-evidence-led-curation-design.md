# Repository Evidence-Led Curation Design

## Context

The module category-grouping refactor reduced the Nix module tree from 81 files
to 42 while preserving every Den aspect path. The active module layout is now
substantially easier to scan, but repository-wide review found a second class
of clutter outside that migration:

- `.superpowers/sdd/` contains 97 tracked execution artifacts totaling roughly
  402 KiB, while the durable Superpowers specifications and plans already live
  under `docs/superpowers/`.
- User constants use ordinal names such as `user_one` and `user_two`, forcing a
  reader to consult `nix/constants.nix` to learn which person each reference
  means.
- The VCS identity check lives beside flake architecture modules instead of in
  a recognizable checks namespace.
- `.github/workflows/nix-lint.yml` repeats the formatting coverage already
  provided by `.github/workflows/ci.yml` through `just ci-check`.
- Stock scaffolding, commented-out assignments, obsolete work markers, and
  copied reference lists obscure active configuration in several files.
- The README explains the repository's purpose but not its physical taxonomy,
  placement rules, or the difference between deployed and dormant assets.

Several apparently unwired assets also exist, including macOS application
data, an empty flake template, and native configuration for Atuin, Sesh,
Swaylock, XDG portals, and Niri. Local history shows that these were added
intentionally. This cleanup therefore classifies them without deleting,
moving, or activating them.

## Goals

- Make the tracked repository leaner and faster to scan after the module
  category-grouping refactor.
- Separate durable design knowledge from transient agent execution state.
- Replace opaque ordinal identifiers with semantic names.
- Make the location of checks and CI responsibilities predictable.
- Remove textual noise without changing active Nix expressions.
- Document where new configuration belongs and which retained assets are not
  currently deployed.
- Preserve evaluated system, user, package, secret, and generated
  configuration behavior.

## Non-goals

- Change packages, settings, secrets, generated configuration, or Den aspect
  paths.
- Change host or user include lists, or introduce implicit category bundles.
- Activate, delete, or relocate dormant and manually managed configuration.
- Remove unused-looking Den helpers that may be part of the repository's
  public aspect surface.
- Consolidate Devenv and the flake-native development shell.
- Refactor repeated SOPS, host, user, shell, or application implementation.
- Change GitHub security scanning or lockfile-maintenance behavior.
- Contact or modify the upstream repository.

## Decision

Use evidence-led curation. Remove only confirmed process residue and redundant
automation, make semantics clearer through behavior-preserving names and
placement, prune comments according to explicit rules, and document uncertain
assets in place.

The active Nix structure remains unchanged except for semantic constant paths
and relocating the existing VCS identity check beneath `nix/checks/`.

## Repository Boundaries

### Active declarative source

The following paths remain the active configuration surface:

- `nix/`: flake composition, inputs, development output, formatting, and
  checks.
- `modules/`: atomic Den aspects grouped by responsibility.
- `lib/`: focused implementations shared behind module facades.
- `dots/`: native application and shell configuration consumed by modules.
- `scripts/`: reusable scripts packaged or documented by the repository.
- `secrets/`: encrypted sops-nix payloads only.
- `flake.nix`: generated from the flake-file declarations in `nix/`.

### Durable project knowledge

`README.md` and `docs/` hold lasting operator guidance, specifications, and
implementation plans. In particular:

- `docs/superpowers/specs/` contains approved designs.
- `docs/superpowers/plans/` contains approved implementation plans.

### Local execution state

`.superpowers/sdd/` is transient implementation state. Its reports, diffs,
snapshots, manifests, briefs, and progress files are not source or durable
project documentation. Remove the currently tracked directory and add the
anchored ignore rule `/.superpowers/sdd/` so future executions remain local.

### Dormant and manually managed assets

Retain these paths in place and label their status in the README:

- `macos/`: manually managed application data that does not use XDG paths and
  is not currently deployed by a Nix module.
- `templates/empty/`: retained empty flake template that is not currently
  exposed through a flake template output.
- Unwired native configurations beneath `dots/config/`, including Atuin,
  Sesh, Swaylock, XDG portal, and Niri material.

Presence in `dots/` does not by itself mean that Home Manager deploys a file.
The README must direct readers to the corresponding Nix module to confirm an
active source reference.

## File Changes

### Execution-artifact policy

Modify `.gitignore` to add:

```gitignore
# Local Superpowers execution state
/.superpowers/sdd/
```

Remove every currently tracked file below `.superpowers/sdd/`. Do not remove
or ignore `docs/superpowers/`.

### Semantic constants

Change `_module.args.constants` in `nix/constants.nix` to this shape without
changing any value:

```nix
_module.args.constants = {
  users = {
    chianyung = "chianyung";
    seraphyne = "seraphyne";
    micha = "micha";
    admin = "admin";
  };
  hosts.esquire.systemDisk = "/dev/disk/by-id/nvme-eui.002538ba11b6cb55";
};
```

Apply these exact reference migrations:

| Existing path | Replacement path |
| --- | --- |
| `constants.user_one` | `constants.users.chianyung` |
| `constants.user_two` | `constants.users.seraphyne` |
| `constants.user_three` | `constants.users.micha` |
| `constants.user_vps` | `constants.users.admin` |
| `constants.disk.pcMain` | `constants.hosts.esquire.systemDisk` |

This is a source-level naming change only. User names, home paths, secret keys,
ownership, groups, host membership, and the Esquire disk path remain
identical.

### Check organization

Move `nix/vcs-identity-tests.nix` to `nix/checks/vcs-identity.nix`. Because
`import-tree` recursively imports `nix/`, no central import list changes.
Adjust the three relative imports from `../lib/shell/vcs/*.nix` to
`../../lib/shell/vcs/*.nix`. Preserve the output name
`checks.vcs-identity` and every assertion.

### CI responsibility

Delete `.github/workflows/nix-lint.yml`. Retain `.github/workflows/ci.yml`,
which runs `just ci-check`; the recipe continues to invoke
`just treefmt-check` followed by `just check`. Retain
`.github/workflows/gitleaks.yml` and `.github/workflows/lockfile-update.yml`
unchanged because they have distinct security and maintenance
responsibilities.

### Comment and scaffold policy

Review tracked `*.nix`, `devenv.nix`, and `devenv.yaml` files and remove only
comments in these classes:

- fully commented-out assignments or module blocks that do not describe an
  active compatibility requirement;
- stock template examples explaining features not configured by this
  repository;
- open work markers whose surrounding sample is not part of an approved plan;
- copied enumerations that can be replaced with a short statement or an
  existing authoritative link;
- comments that merely restate an immediately adjacent option or package name.

Retain comments in these classes:

- category and aspect section labels;
- compatibility notes and upstream issue references;
- security, secret-handling, and platform-specific warnings;
- explanations of non-obvious values, assertions, service overrides, or
  ordering;
- dormant-asset files themselves.

The cleanup must not add, remove, reorder, or change an active Nix assignment
while pruning comments. Active Devenv environment variables, packages, tasks,
tests, and hooks remain unchanged even when they appear unnecessary.

### Repository guide

Expand `README.md` with:

1. A compact tree describing the responsibility of each tracked top-level
   source directory.
2. Placement rules:
   - atomic Den aspects belong in the relevant semantic category under
     `modules/`;
   - large focused implementations shared behind a facade belong under
     `lib/`;
   - native application files belong under `dots/config/<application>/` and
     require an explicit module reference to be deployed;
   - flake checks belong under `nix/checks/`;
   - reusable operational commands belong under `scripts/` and should be
     exposed through a module, documentation, or `justfile`;
   - encrypted secrets belong under `secrets/` and must be declared through
     sops-nix;
   - durable designs and plans belong under `docs/superpowers/`, while local
     execution state belongs under ignored `.superpowers/sdd/`.
3. A retained-assets note for `macos/`, `templates/empty/`, and unwired native
   configurations.
4. A development-workflow note naming Devenv/Direnv as the primary environment
   and `nix develop` as the retained flake-native alternative.

## Migration Strategy

1. Record the clean Jujutsu state and current structural and evaluation
   baseline.
2. Add the execution-state ignore rule and remove tracked `.superpowers/sdd/`
   artifacts.
3. Rename constants and all references as one atomic change.
4. Move the VCS identity check and adjust only its relative imports.
5. Remove the redundant Nix lint workflow.
6. Prune comments according to the approved mechanical policy.
7. Expand the README with the repository map and placement guide.
8. Run structural, formatting, evaluation, security, and diff verification.

Each step remains independently reviewable in Jujutsu. No operation may
contact the upstream repository.

## Risk Controls

The primary risks are deleting durable knowledge with execution residue,
missing a constant reference, changing a Nix expression while pruning
comments, breaking a relative import during the check move, or accidentally
reducing CI coverage.

Controls:

- Limit execution-state removal to the anchored `.superpowers/sdd/` path and
  verify `docs/superpowers/` remains tracked.
- Search for every old constant path before and after the migration.
- Compare the Den declaration and consumed-include inventories before and
  after; both must remain identical.
- Move all constant definitions and references in one cleanup unit.
- Preserve every assertion and the output name in the VCS identity check.
- Confirm `ci.yml` still reaches both `treefmt-check` and `check` through the
  `ci-check` recipe before deleting the duplicate workflow.
- Use formatter and Nix evaluation as syntax guards after comment cleanup.
- Inspect the final `jj diff` for active-expression changes, not only passing
  commands.
- Treat a pre-existing failure as a baseline limitation only when the final
  failure matches it; do not expand this cleanup to fix unrelated defects.

## Verification Strategy

### Structural verification

- `jj status` is clean before implementation.
- No path below `.superpowers/sdd/` remains tracked after implementation.
- The ignore rule is anchored to the repository root.
- Every existing specification and plan below `docs/superpowers/` remains.
- No occurrence of `constants.user_one`, `constants.user_two`,
  `constants.user_three`, `constants.user_vps`, or `constants.disk.pcMain`
  remains.
- `nix/checks/vcs-identity.nix` exists and
  `nix/vcs-identity-tests.nix` does not.
- `.github/workflows/nix-lint.yml` is absent and the other three workflows
  remain.

### Interface verification

- Compare exact before-and-after inventories of declared Den aspect paths.
- Compare exact before-and-after inventories of angle-bracket aspect includes.
- Evaluate each semantic constant and confirm its value matches the prior
  ordinal constant.
- Confirm the flake still exposes `checks.vcs-identity`.
- Confirm `just ci-check` still expands to formatting followed by the full
  check.

### Formatting and checks

Run:

```bash
just treefmt-check
nix build 'path:.#checks.x86_64-linux.vcs-identity' --print-build-logs
just check
just secrets-scan
```

### Cross-platform evaluation

Evaluate all configured NixOS hosts, the configured nix-darwin host, and the
standalone Home Manager output supported by the recorded baseline. A blocked
or pre-existing failure must be reported with its exact message and compared
to the baseline.

### Final review

Inspect `jj diff --summary` and the complete `jj diff`. The final change may
contain only:

- removal and ignoring of `.superpowers/sdd/` artifacts;
- semantic constant-path changes with identical values;
- the VCS identity check move and relative-import adjustment;
- removal of the redundant CI workflow;
- comment-only pruning;
- README and approved Superpowers documentation changes.

## Acceptance Criteria

- `.superpowers/sdd/` is ignored and has no tracked files.
- `docs/superpowers/` retains all durable designs and plans.
- All constant references use semantic user and host names, with identical
  evaluated values.
- The VCS identity check lives under `nix/checks/` and retains its output and
  assertions.
- CI formatting and full-check coverage remain intact without the duplicate
  workflow.
- Active source contains less stale scaffold and commented-out configuration,
  while rationale and safety comments remain.
- The README makes repository ownership, placement, and dormant status clear.
- No Den aspect path, include path, package, setting, secret, generated file,
  host membership, user configuration, or platform behavior changes.
- Final verification introduces no failure beyond a precisely matching
  recorded baseline limitation.

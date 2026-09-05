# Category-First Repository Structure Design

## Context

The repository already uses Den aspects to expose small, independently
selectable configuration units. A previous category-grouping refactor reduced
the module tree from 81 Nix files to 42, but several physical files now combine
too many independent responsibilities:

- `modules/shell/llm-agents.nix` is 444 lines;
- `modules/shell/shells.nix` is 345 lines;
- `modules/secrets/sops.nix` is 318 lines;
- `modules/shell/packages.nix` is 281 lines;
- `modules/apps/browsers.nix` is 262 lines; and
- `modules/desktop/quickshell.nix` is 237 lines.

The top-level boundaries are broadly correct, but navigation becomes difficult
inside these grouped files. Relative references such as `../../dots` also make
physical moves noisy and fragile. The repository needs a middle ground between
one tiny file per aspect and category megafiles.

## Goals

- Make technical categories the primary navigation model.
- Make feature locations predictable from their responsibility and name.
- Keep files locally understandable without creating excessive fragmentation.
- Preserve every existing public Den aspect path and its independent
  enablement.
- Preserve NixOS, nix-darwin, and Home Manager behavior.
- Remove directory-depth coupling from references to repository assets.
- Clearly distinguish active, dormant, and manually managed native
  configuration without relocating it.
- Keep future additions consistent through documented placement rules.

## Non-goals

- Rename, alias, merge, or remove public Den aspect paths.
- Change host or user composition.
- Change packages, application settings, service options, secret declarations,
  or generated configuration content.
- Move, delete, or activate dormant files under `dots/`.
- Replace Den, the dendritic pattern, `import-tree`, flake-file, or sops-nix.
- Move the generated `flake.nix` away from the repository root.
- Contact or modify the upstream repository.
- Enforce file size mechanically when the code is cohesive.

## Decision

Adopt a category-first hybrid structure. Technical categories remain the
primary directories, while subcategories are introduced where a category has
multiple substantial responsibilities. Leaf files represent a feature, public
aspect, or cohesive implementation unit.

Use at most two directory levels below a technical category. Aim for roughly
40-180 lines per Nix file. Review files above 200 lines for separable
responsibilities, but do not split cohesive code solely to satisfy a line-count
target. Small related aspects may remain together when the combined file is
easy to scan.

Physical filenames do not define the Den interface. For example,
`modules/shell/ai/agents.nix` continues declaring `<shell/llm_agents>`.

## Repository Boundaries

The existing top-level responsibilities remain stable:

| Path | Responsibility |
| --- | --- |
| `nix/` | Flake composition, pinned inputs, development outputs, formatting, and checks |
| `modules/` | Public Den aspects organized by technical responsibility |
| `lib/` | Focused builders and generators used behind module facades |
| `data/` | Non-secret declarative metadata |
| `dots/` | Native application and shell configuration, including retained dormant assets |
| `scripts/` | Reusable operational scripts |
| `secrets/` | Encrypted sops-nix payloads only |
| `docs/` | Durable operator and design documentation |
| `macos/` | Manually managed non-XDG macOS application data |
| `templates/` | Retained project templates |

`modules/` is the primary map for answering “what configures this feature?”
`lib/` is not a parallel taxonomy and must contain only implementation that
would make a module facade difficult to scan.

## Target Module Organization

The intended shape is:

```text
modules/
├── shell/
│   ├── ai/
│   ├── shells/
│   ├── packages/
│   ├── prompt/
│   ├── multiplexer/
│   └── vcs.nix
├── apps/
│   ├── browsers/
│   ├── editors/
│   └── terminals/
├── system/
├── desktop/
├── services/
├── secrets/
├── hosts/
└── users/

lib/
├── shell/
│   ├── ai/
│   └── vcs/
└── secrets/
    └── sops/
```

Subdirectories are introduced only when they contain multiple meaningful
files. Existing compact files do not need an otherwise empty directory merely
for visual symmetry.

### Shell

| Current file | Target responsibility |
| --- | --- |
| `shell/llm-agents.nix` | `shell/ai/instructions.nix` for `<shell/ai>` and `shell/ai/agents.nix` for `<shell/llm_agents>` |
| `shell/shells.nix` | `shell/shells/bash.nix`, `environment.nix`, `fish.nix`, and `zsh.nix` |
| `shell/packages.nix` | `shell/packages/profiles.nix`, `utilities.nix`, and `scripts.nix` |
| `shell/prompt.nix` | `shell/prompt/fastfetch.nix` and `starship.nix` |
| `shell/terminal-multiplexer.nix` | `shell/multiplexer/herdr.nix`, `workmux.nix`, `tmux.nix`, and `zellij.nix` |

AI configuration generators are split into `lib/shell/ai/mcp.nix`,
`codex.nix`, `grok.nix`, `opencode.nix`, `pi.nix`, and `cursor.nix`. The
`agents.nix` facade owns deployment, session variables, packages, and the
stable `<shell/llm_agents>` declaration.

The existing VCS facade and helpers remain the model for justified extraction,
and `modules/shell/vcs.nix` remains at its current path. Compact files such as
formatters, Homebrew, 1Password, and file-navigation configuration remain
intact in this refactor.

### Applications

Grouped application files are split by application beneath their technical
subcategory:

- `apps/browsers/{chromium,firefox,zen}.nix`;
- `apps/editors/{datagrip,vscode,zed}.nix`; and
- `apps/terminals/{ghostty,wezterm}.nix`.

Standalone applications such as Discord and Handy remain standalone files.
Their public paths stay `<apps/discord>` and `<apps/handy>`.

### System and desktop

Apply these exact splits:

- `system/desktop-support.nix` becomes `system/desktop/fonts.nix` and
  `system/desktop/xdg.nix`;
- `system/boot.nix` becomes `system/boot/bootloaders.nix` and
  `system/boot/impermanence.nix`; and
- `desktop/quickshell.nix` becomes `desktop/quickshell/noctalia.nix` and
  `desktop/quickshell/dms.nix`.

Compact hardware, networking, platform, virtualization, display-manager,
desktop-environment, and window-manager files remain grouped while they are
easy to scan. Distinct public aspect paths remain independently selectable even
when several are declared in one compact file.

### Secrets

Move reusable Home Manager, NixOS, and Darwin sops-nix builders to
`lib/secrets/sops/builders.nix`. Replace `modules/secrets/sops.nix` with
`modules/secrets/sops/base.nix`, `vps.nix`, `esquire.nix`, `acerus.nix`, and
`mbp.nix`. The base file owns `<secrets/sops>` and the named files own their
matching providers while preserving paths such as `<secrets/sops/esquire>`.

No secret values move into Nix source. Encrypted YAML remains under
`secrets/<host>/`, and all declarations continue using sops-nix.

### Flake composition

Reduce `nix/dendritic.nix` to the Den/flake-file composition concern. Split its
`flake-file.inputs` declaration into `nix/inputs/core.nix`, `system.nix`,
`desktop.nix`, and `tooling.nix`. Core owns flake composition and Home Manager
inputs; system owns NixOS, Darwin, storage, boot, Homebrew, and secrets inputs;
desktop owns graphical environment and application inputs; tooling owns VCS,
agent, and workspace-tool inputs. Multiple declarations merge through the
existing module system and continue generating the root `flake.nix` through
`just write-flake`.

## Stable Source Layout

Introduce repository paths in `nix/den.nix` as shared module arguments next to
the existing Den arguments:

```nix
_module.args.paths = {
  root = ../.;
  dots = ../dots;
  scripts = ../scripts;
  secrets = ../secrets;
};
```

Modules use these values instead of directory-depth-sensitive references:

```nix
xdg.configFile."ghostty".source = paths.dots + "/config/ghostty";
```

The migration covers active references beneath `modules/`, `lib/`, and `nix/`.
Relative paths local to a feature directory may remain when both files move as
one cohesive unit. The central paths do not change how Nix copies source paths
into the store.

## File Conventions

Module files follow a predictable shape:

```nix
{ inputs, paths, ... }:
let
  # Imports and focused local helpers.
in
{
  # Public aspect declaration.
}
```

When applicable, aspect fields appear in this order:

1. `includes`;
2. `provides`;
3. `nixos`;
4. `darwin`; and
5. `homeManager`.

Additional conventions:

- use kebab-case physical filenames and descriptive bindings;
- avoid ambiguous `default.nix` and `index.nix` leaf files;
- explain compatibility, security, ordering, or non-obvious decisions in
  comments instead of restating adjacent options;
- define shared data once and keep platform-specific outputs explicit;
- retain long package lists directly when their labeled groups remain easier
  to understand than an abstraction; and
- keep host-specific overrides in host aspects.

## Native Configuration Status

All native configuration remains under `dots/`. Add `dots/README.md` with a
compact inventory containing:

- the configuration path;
- status: `active`, `dormant`, or `manual`;
- the consuming Nix module for active content; and
- a short note for dormant or manual content.

The inventory is documentation, not an activation mechanism. A file is active
only when a Nix module explicitly references it. Atuin, Sesh, Swaylock, Niri,
and XDG portal material remains in place unless later evidence changes its
classification.

## Data Flow and Compatibility

Runtime and evaluation flow remains unchanged:

```text
import-tree
    -> physical Nix module files
    -> existing den.aspects attributes
    -> host and user includes
    -> NixOS, nix-darwin, and Home Manager outputs
```

Moving a declaration changes only its source location. Every public aspect
path, provider path, host/user include, package selection, option value, secret
key, and generated configuration must remain identical.

## Migration Strategy

1. Record the structural and evaluation baseline, including declared aspects
   and consumed include paths.
2. Add the shared `paths` argument and migrate repository asset references.
3. Split flake input declarations while preserving generated `flake.nix`.
4. Refactor `modules/shell/` and verify it independently.
5. Refactor applications, system, desktop, and secrets one category at a time,
   verifying after each category.
6. Add the native-configuration status inventory and update repository
   placement guidance.
7. Run complete structural, formatting, test, and cross-platform evaluation
   verification.

Each replaced file and all of its destinations change together so import-tree
never observes duplicate public definitions. The migration does not contact
upstream.

## Error Handling and Risk Controls

The main risks are omitted or duplicate aspects, changed merge semantics,
broken source paths, configuration drift during extraction, and inaccurate
dormant-asset classification.

Controls:

- capture and compare the exact declared Den aspect inventory;
- capture and compare every `<...>` include consumed by hosts and users;
- introduce one shared path family at a time and evaluate immediately;
- preserve complete function arguments and closures when extracting helpers;
- keep each category migration independently reviewable;
- search for remaining legacy repository-relative references;
- inspect the local diff for value changes, not just successful evaluation;
- keep encrypted secret payloads and sops-nix declarations separate; and
- record pre-existing failures before refactoring and require the final result
  not to introduce new failures.

The primary version-control workflow remains Jujutsu. If a managed checkout
does not expose Jujutsu metadata, local Git commands may be used only as a
non-upstream fallback for status, diff, and commits.

## Verification Strategy

### Structural verification

- Compare before/after Den aspect inventories exactly.
- Compare host and user include inventories exactly.
- Confirm every planned destination exists and every replaced source is gone.
- Confirm no duplicate public aspect declarations were introduced.
- Search active Nix code for obsolete `../../dots`, `../../scripts`, and
  `../../secrets` references covered by the shared paths.
- Confirm dormant and manual native assets remain in place and unwired.

### Formatting and tests

- Run `nix fmt` as needed during migration.
- Run `just treefmt-check` on the final tree.
- Run all repository shell tests beneath `tests/`.
- Run `nix flake check --print-build-logs` or the repository's equivalent
  `just` verification recipe.

### Cross-platform evaluation

- Evaluate all configured NixOS hosts and installer variants.
- Evaluate the configured nix-darwin host.
- Evaluate Home Manager configurations reached through host/user composition.
- Regenerate `flake.nix` and confirm there is no unexpected generated diff.

When a baseline command already fails for an unrelated reason, the final
report must identify the matching baseline limitation rather than claiming a
successful check.

## Acceptance Criteria

- Technical categories are the primary navigation path.
- Large mixed-responsibility files are replaced by cohesive feature files.
- No new directory nesting exceeds two levels below its technical category.
- Existing public Den aspect and provider paths remain unchanged.
- Host and user include paths remain unchanged.
- NixOS, nix-darwin, and Home Manager evaluations introduce no regression.
- Active repository asset references use stable shared paths where applicable.
- Native configuration remains under `dots/` and has documented deployment
  status.
- No package, option, secret, generated configuration, or host composition
  changes as part of the structural refactor.
- Repository formatting, tests, and flake checks pass or match documented
  pre-existing baseline limitations.

# Category-First Repository Structure Implementation Plan

> **For agentic workers:** Use `superpowers:executing-plans` to execute task by task. `superpowers:subagent-driven-development` is an alternative when delegation is authorized. Steps use checkboxes for progress tracking.

**Goal:** Make configuration easier to locate and read through technical categories and cohesive files, preserving the public Den interface and evaluated behavior.

**Architecture:** Retain Den and recursive import-tree discovery. Split mixed-responsibility modules into category subdirectories, extract AI generators and SOPS builders into explicit helpers, and supply stable repository asset paths through lexical module arguments.

**Tech Stack:** Nix Flakes, flake-parts, Den, import-tree, flake-file, NixOS, nix-darwin, Home Manager, sops-nix, Bash, Just, Jujutsu.

**Spec:** [Category-first design](../specs/2026-09-05-category-first-repository-structure-design.md).

## Execution record — 2026-09-05

The source migration in Tasks 2–10 has been applied. Tasks 1 and 11 have local
verification evidence, with full flake/host evaluation still blocked by the
sandbox's Nix daemon socket permissions. Unchecked verification steps below
remain outstanding; they are not implied to pass by source-task completion.

Evidence collected in this execution:

- Existing managed worktree: `declutter-config-file`; Jujutsu metadata is not
  available, and Git metadata remains outside the writable sandbox. No commit
  or upstream operation was performed.
- Both `nixos-installer` and `herdr-plugin-reconcile` shell suites passed before
  and after the migration.
- Direct `nixfmt --check` and `deadnix -L --fail` passed for `modules/`, `lib/`,
  and `nix/`. Nix's offline evaluator parsed/imported all 94 Nix files there.
- Offline Nix comparison preserved the public aspect/provider/field inventory
  for all 12 split groups and the exact input attribute values.
- Offline fixture evaluation produced identical AI configuration strings for
  Linux and Darwin, and identical SOPS base/provider module values after
  accounting for the baseline copy's source paths. This is not a full Den or
  Home Manager integration evaluation.
- A source comparison checked 26 complete moved aspect assignments, allowing
  only formatting and the explicit asset-path substitutions.
- Native assets, encrypted YAML, host/user files, `flake.nix`, and `flake.lock`
  were compared byte-for-byte and remain unchanged. `dots/README.md` is new.
- Statix's existing repeated-key warnings decreased from 24 to 19 in
  `modules/` and 3 to 2 in `nix/`; `lib/` has none. No new warning category
  remains. Statix is not reported as globally clean.
- README links resolve and every native application subtree is represented
  in the status inventory.

Baseline copies and temporary comparison harnesses are under
`/tmp/dotnix-declutter.jcr5j0/` (`verify.nix`, `compare.py`). They are local
execution artifacts, not project dependencies.

Still required in a daemon-enabled environment: full `nix flake check`, the
NixOS/Darwin/Home Manager evaluation matrix, focused derivation builds, and
`write-flake` regeneration. Attempts at flake check, Darwin evaluation, and
write-flake failed before evaluation with `Operation not permitted` on the
daemon socket. The unchanged generated flake and identical input attrsets
provide local evidence, not a substitute for regeneration.

Use a consistent `path:` reference until newly created files are included in
the local VCS snapshot. Do not interpret the old Git-tracked source set as the
candidate implementation.

## Global constraints

- Preserve every public aspect and provider path, including underscores and historical names.
- Preserve host/user includes, packages, option values, list ordering, secret keys, template content, and platform behavior.
- Keep dormant assets in place; do not activate, delete, or relocate them.
- Keep `flake.lock` and generated input declarations equivalent. Use modern Nix CLI commands only.
- Use sops-nix exclusively for secrets; inspect declarations without decrypting payloads.
- Technical categories remain the navigation model. Maximum nesting is two directory levels below a technical category.
- Aim for 40–180 lines, reviewing files above 200 lines by responsibility rather than enforcing a numeric ceiling.
- Use kebab-case filenames, descriptive bindings, and comments explaining reasons. Order aspect fields as `includes`, `provides`, `nixos`, `darwin`, `homeManager` when present; preserve ordering inside lists and generated strings. Avoid adding ambiguous `default.nix` or `index.nix` files.
- Preserve unrelated working-copy changes. Use local Jujutsu; never contact upstream.
- Use `apply_patch` for edits. Do not change package versions or fix unrelated baseline failures during extraction.

## Execution context and deviations resolved during planning

This is one structural migration with shared compatibility checks; the category tasks below are its reviewable increments. They do not require separate subsystem designs.

The current checkout is already an isolated managed worktree. Earlier checks found no Jujutsu metadata and Git metadata outside the writable sandbox. Do not retry commits that fail for that same permission boundary. Record completed tasks in the working copy; a local commit can be made when metadata is writable. No push, fetch, or pull is part of this plan.

`nix flake metadata --json .` failed during planning because the sandbox cannot access the Nix daemon socket. This is an environment limitation, not an established configuration failure. Runtime evaluation must be performed in an environment with daemon access before claiming behavioral verification.

The actual formatting recipe is `just fmt-check`, not the spec's historical `just treefmt-check`. Use the existing recipe; do not add a redundant alias. The formatter currently does not cover Markdown, so documentation also receives manual review.

## File map and ownership

Paths in braces below enumerate exact files, not optional choices.

| Existing source | Destination and responsibility |
| --- | --- |
| `nix/den.nix` | Add `paths`; retain existing Den wiring |
| `nix/dendritic.nix` | Retain imports, outputs expression, and nixConfig; extract inputs |
| Input declarations | `nix/inputs/{core,system,desktop,tooling}.nix` |
| `modules/shell/llm-agents.nix` | `modules/shell/ai/{instructions,agents}.nix` |
| AI generator bindings | `lib/shell/ai/{mcp,codex,grok,opencode,pi,cursor}.nix` |
| `modules/shell/shells.nix` | `modules/shell/shells/{bash,environment,fish,zsh}.nix` |
| `modules/shell/packages.nix` | `modules/shell/packages/{profiles,utilities,scripts}.nix` |
| `modules/shell/prompt.nix` | `modules/shell/prompt/{fastfetch,starship}.nix` |
| `modules/shell/terminal-multiplexer.nix` | `modules/shell/multiplexer/{herdr,workmux,tmux,zellij}.nix` |
| `modules/shell/herdr-plugin-reconcile.sh` | Retain current location and contents; consumers use `paths.root` |
| `modules/apps/browsers.nix` | `modules/apps/browsers/{chromium,firefox,zen}.nix` |
| `modules/apps/editors.nix` | `modules/apps/editors/{datagrip,vscode,zed}.nix` |
| `modules/apps/terminals.nix` | `modules/apps/terminals/{ghostty,wezterm}.nix` |
| `modules/system/desktop-support.nix` | `modules/system/desktop/{fonts,xdg}.nix` |
| `modules/system/boot.nix` | `modules/system/boot/{bootloaders,impermanence}.nix` |
| `modules/desktop/quickshell.nix` | `modules/desktop/quickshell/{noctalia,dms}.nix`; Noctalia file also owns the small base aspect |
| `modules/secrets/sops.nix` | `modules/secrets/sops/{base,vps,esquire,acerus,mbp}.nix` |
| SOPS helper bindings | `lib/secrets/sops/builders.nix` |
| Repository guidance | Update `README.md`; create `dots/README.md` |

`modules/shell/vcs.nix`, compact shell categories, host/user modules, Disko layouts, and compact system/service modules retain their locations. Asset-reference edits may touch these files without changing their boundaries. Historical design documents remain historical.

## Verification protocol used by every task

Use characterization of existing behavior rather than tests that assert a preferred file count. Keep baseline evidence in a task-specific temporary directory created by `mktemp -d`; record its actual path in the execution notes. Use `apply_patch` to create any temporary comparison expressions. Never put helper Nix expressions under auto-imported `nix/` or `modules/` unless they are flake modules.

Before changing source, capture:

```bash
jj status
rg -n 'den\.aspects|provides\s*=|includes\s*=' modules --glob '*.nix'
rg --no-filename -o '<[^>]+>' modules/hosts modules/users | sort
rg -n 'import |builtins.readFile|\.source\s*=' modules lib nix --glob '*.nix'
sha256sum flake.nix flake.lock
just fmt-check
bash tests/nixos-installer.sh scripts/nixos-installer.sh .
bash tests/herdr-plugin-reconcile.sh
nix flake check --no-update-lock-file --accept-flake-config --print-build-logs
```

`rg` declarations are a navigation aid, not a complete Den API inventory: explicitly expand nested `provides` and `_` definitions and function-valued host aspects into a ledger of public paths, source files, and owned fields. Compare that ledger after every split. Preserve empty aspects and base providers as well as leaf declarations.

Evaluate all host and embedded Home Manager derivations before and after:

```bash
for target in acerus acerus-installer esquire esquire-installer vps; do
  nix eval --no-update-lock-file --raw ".#nixosConfigurations.$target.config.system.build.toplevel.drvPath"
  nix eval --no-update-lock-file --json ".#nixosConfigurations.$target.config.home-manager.users" \
    --apply 'users: builtins.mapAttrs (_: user: user.home.activationPackage.drvPath) users'
done
nix eval --no-update-lock-file --raw '.#darwinConfigurations.mbp.system.drvPath'
nix eval --no-update-lock-file --json '.#darwinConfigurations.mbp.config.home-manager.users' \
  --apply 'users: builtins.mapAttrs (_: user: user.home.activationPackage.drvPath) users'
```

Use the same flake source mode before and after. New files must be included in the local VCS snapshot before using `.#` evaluation. If metadata is unwritable, use a `path:` flake reference consistently for both baseline and candidate, and report that distinction. Do not evaluate a candidate whose new files are silently omitted by Git-backed flake filtering.

Derivation differences require investigation, not automatic rejection or normalization: source-root store paths can change when source files move. Compare the affected generated text, package selections, service settings, and SOPS declarations to distinguish source-location changes from behavior changes. Do not serialize the entire recursive NixOS configuration or decrypt secrets. For SOPS templates, compare content containing placeholders and metadata only.

On a category task, run `just fmt-check`, its listed focused checks, the aspect ledger comparison, and the relevant host evaluations. On final integration, run the entire matrix once. Missing builders, daemon access, or uncached inputs are reported separately from expression/assertion failures.

Each completed task ends with a local diff review. If Jujutsu is available and the current change contains only task-owned edits, describe that change and start the next local change. Do not include unrelated edits or attempt blocked Git metadata writes.

## Task 1: Capture the baseline and validate the execution environment

**Files:** Read `AGENTS.md`, the spec, `flake.nix`, `flake.lock`, `justfile`, `nix/checks/*.nix`, `modules/hosts/*.nix`, and `modules/users/*.nix`. No production edits.

**Interface:** Produces the baseline logs, API ledger, include inventory, and source hashes used by Tasks 2–11.

- [x] Check local working-copy state and available Nix daemon access. Preserve existing changes and use the managed worktree already supplied.
- [ ] Capture the verification protocol above, including individual exit statuses. A failing check must not prevent recording the remaining independent checks.
- [x] Record hashes of native payload files and encrypted secret payloads with `rg --files -0 dots secrets macos | sort -z | xargs -0 sha256sum`; keep the result outside the tracked source tree.
- [x] Expand the public API ledger, including `shell/packages/dev`, `shell/packages/personal`, `desktop/qs`, both Quickshell providers, all bootloader providers, and all SOPS providers.
- [ ] Record generated-template content/metadata and configured source destinations for the affected active hosts using targeted projections. For example, run the following before and after the migration; it reads declarative placeholders, not decrypted data:

```bash
nix eval --no-update-lock-file --json \
  '.#nixosConfigurations.acerus.config.home-manager.users.seraphynee' \
  --apply 'c: {
    templates = builtins.mapAttrs (_: t: { inherit (t) path mode content; }) c.sops.templates;
    files = builtins.mapAttrs (_: f: {
      inherit (f) target text;
      source = if f.source == null then null else toString f.source;
    }) c.home.file;
    packages = map (p: p.name) c.home.packages;
    variables = c.home.sessionVariables;
  }'
```

Repeat with the matching host/user selectors from the host matrix. Retain exact generated text for comparison; investigate embedded source-store paths individually.
- [ ] Review the baseline for unresolved evaluation failures before beginning behavioral extraction. If daemon access remains unavailable, structural edits can be reviewed but final verification remains outstanding.

## Task 2: Introduce stable asset paths and update direct consumers

**Files:** Modify `nix/den.nix`; asset consumers returned by the baseline search under `modules/`, `lib/`, and `nix/`; specifically `lib/shell/vcs/git.nix`, `modules/shell/vcs.nix`, `nix/checks/vcs-identity.nix`, and `nix/checks/ssh-bookmarks.nix`.

**Interface:** `paths = { root: Path; dots: Path; scripts: Path; secrets: Path; }`. This is a flake-module argument, not an automatically inherited Home Manager argument.

- [x] Add the following alongside `__findFile` in `nix/den.nix`:

```nix
_module.args.paths = {
  root = ../.;
  dots = ../dots;
  scripts = ../scripts;
  secrets = ../secrets;
};
```

- [x] Add `paths` to each affected outer flake-module argument list and capture it lexically in nested NixOS/Darwin/Home Manager functions. Replace asset paths without changing source/text/recursive deployment semantics:

```nix
xdg.configFile."ghostty".source = paths.dots + "/config/ghostty";
text = builtins.readFile (paths.scripts + "/nixos-installer.sh");
```

- [x] For the Git Home Manager helper, use a curried dependency boundary:

```nix
# lib/shell/vcs/git.nix
{ paths }:
{ config, lib, pkgs, ... }:
# Existing expression body, with paths.dots replacing its native asset path.
```

Update its entry in `modules/shell/vcs.nix` and `nix/checks/vcs-identity.nix` to `(import (paths.root + "/lib/shell/vcs/git.nix") { inherit paths; })`. Leave helper module imports that need no repository argument unchanged.

- [x] Add `paths` to `nix/checks/ssh-bookmarks.nix` and pass `inherit paths;` when it directly imports `modules/shell/1password.nix`. Search all direct imports for other affected call sites.
- [x] Keep `imports` discovery independent of `_module.args.paths`: use literal paths for flake-module imports to avoid module-argument recursion. Helpers outside the auto-imported trees are imported explicitly.
- [x] Retain runtime tool path strings such as Treefmt's `--config-path=dots/config/stylua/stylua.toml.tmpl`; these are project-relative CLI arguments, not Nix source paths.
- [ ] Run formatter, host evaluations, installer tests, and focused checks:

```bash
nix build --no-link --no-update-lock-file .#checks.x86_64-linux.vcs-identity .#checks.x86_64-linux.ssh-bookmarks
bash tests/nixos-installer.sh scripts/nixos-installer.sh .
```

- [ ] Compare source destinations/template bytes to baseline and review the local diff. Suggested local description: `refactor: centralize repository asset paths`.

## Task 3: Split flake input declarations

**Files:** Modify `nix/dendritic.nix`; create `nix/inputs/{core,system,desktop,tooling}.nix`. Preserve `nix/treefmt.nix`, `flake.lock`, and generated `flake.nix` content.

**Interface:** Each new file returns `{ flake-file.inputs = { ... }; }`, with existing input attributes copied verbatim.

- [x] Move complete input blocks according to this exhaustive mapping:

| Destination | Inputs |
| --- | --- |
| `core.nix` | nixpkgs, nixpkgs-lib, den, flake-file, flake-aspects, flake-parts, import-tree, systems, systems-linux, home-manager, hjem |
| `system.nix` | nixos-anywhere, nix-homebrew, brew-src, homebrew-core, homebrew-cask, nix-index-database, disko, lanzaboote, impermanence, nixos-wsl, darwin, sops-nix |
| `desktop.nix` | handy, catppuccin, zen-browser, noctalia, noctalia-greeter, noctalia-qs, dms, niri, mango, msnap, helium |
| `tooling.nix` | momoi-say, worktrunk, herdr, herdr-automatic-rename, herdr-hunk-diff, herdr-plus, herdr-worktree-setup, herdr-flash, herdr-last, hunk, llm-agents, workmux |

- [x] Preserve `treefmt-nix` beside its consumer in `nix/treefmt.nix`; it is not part of the extracted declaration.
- [x] Remove only the moved input attrset from `nix/dendritic.nix`, retaining its imports, outputs string, cache configuration, and compatibility comments.
- [ ] Run `just write-flake`, `just fmt-check`, and compare `sha256sum flake.nix flake.lock` with baseline. Expected: no content change in either file.
- [x] Review input names, `follows`, `flake = false`, revisions, and nested Hunk/system overrides. Suggested description: `refactor: group flake inputs by technical category`.

## Task 4: Extract AI client generators

**Files:** Replace `modules/shell/llm-agents.nix` with `modules/shell/ai/{instructions,agents}.nix`; create `lib/shell/ai/{mcp,codex,grok,opencode,pi,cursor}.nix`.

**Interfaces:** All generators return the existing serialized strings. Export the following names:

| Helper | Input and output |
| --- | --- |
| `mcp.nix` | `config -> servers`; move `mkMcpServers` verbatim |
| `codex.nix` | `{ mkMcpServers } -> { mkCodexConfig; }`; retain internal `mkCodexMcpServer` |
| `grok.nix` | `{ mkMcpServers } -> { mkGrokConfig; }`; retain internal `mkGrokMcpServer` |
| `opencode.nix` | `{ mkMcpServers } -> { mkOpencodeConfig; }` |
| `pi.nix` | `{ mkMcpServers } -> { mkPiConfig; mkPiMcpConfig; }`; `mkPiConfig` remains a string |
| `cursor.nix` | `{ mkMcpServers } -> { mkCursorCliConfig; mkCursorMcpConfig; }`; CLI config remains a string |

- [x] Move the existing function bodies without changing serializers, whitespace within strings, package arrays, model settings, or disabled-server semantics.
- [x] Wire the imports in the outer lexical scope of `agents.nix`:

```nix
let
  mkMcpServers = import (paths.root + "/lib/shell/ai/mcp.nix");
  inherit (import (paths.root + "/lib/shell/ai/codex.nix") { inherit mkMcpServers; }) mkCodexConfig;
  inherit (import (paths.root + "/lib/shell/ai/grok.nix") { inherit mkMcpServers; }) mkGrokConfig;
  inherit (import (paths.root + "/lib/shell/ai/opencode.nix") { inherit mkMcpServers; }) mkOpencodeConfig;
  inherit (import (paths.root + "/lib/shell/ai/pi.nix") { inherit mkMcpServers; }) mkPiConfig mkPiMcpConfig;
  inherit (import (paths.root + "/lib/shell/ai/cursor.nix") { inherit mkMcpServers; }) mkCursorCliConfig mkCursorMcpConfig;
in
```

- [x] Keep the full function-valued `<shell/llm_agents>` declaration and its `{ user, ... }` argument in `agents.nix`. Keep the unchanged `<shell/ai>` declaration in `instructions.nix`.
- [ ] Compare each generated string to its pre-extraction result using the same fixture `config.sops.placeholder` values and username, for both Linux and Darwin branches of `mkCodexConfig`. Use harmless sentinel placeholders; do not load decrypted secrets. Exact string equality is the expected result.
- [ ] Evaluate Seraphynee's embedded Home Manager configuration on Acerus and compare template path/mode/content, session variables, aliases, and package selections. Run formatting and the API ledger comparison.
- [ ] Review that helpers are outside import-tree discovery and no new public client aspects were added. Suggested description: `refactor: separate AI settings generators`.

## Task 5: Split shells and shared environment

**Files:** Replace `modules/shell/shells.nix` with `modules/shell/shells/{bash,environment,fish,zsh}.nix`; update the source-location comment in `modules/shell/vcs.nix`.

**Interface:** Preserve `<shell/bash>`, `<shell/env>`, `<shell/fish>`, and `<shell/zsh>` exactly.

- [x] Extract the whole Bash declaration into `bash.nix`.
- [x] Extract both `env.homeManager` and `env.nixos`, including all runtime-secret and XDG rendering helpers, into `environment.nix`.
- [x] Extract the complete Fish declaration into `fish.nix`; keep platform aliases, init priority, plugin revision/hash, key bindings, and function bodies unchanged.
- [x] Extract the complete Zsh declaration into `zsh.nix`; keep `lib.mkOrder 1000`, source globs, and abbreviation loading order unchanged.
- [x] Update the Worktrunk comment to point at `modules/shell/shells/zsh.nix`. Do not change integration ownership between these aspects.
- [ ] Compare generated shell init content, exported variables, XDG files, and runtime-secret path mappings with baseline; evaluate Acerus, Esquire, VPS, and MBP Home Manager configurations. Run formatting and SSH/VCS checks from Task 2.
- [ ] Review the API ledger and diff. Suggested description: `refactor: separate shell and environment modules`.

## Task 6: Split package profiles and shell presentation

**Files:** Replace `modules/shell/packages.nix` with `modules/shell/packages/{profiles,utilities,scripts}.nix`; replace `modules/shell/prompt.nix` with `modules/shell/prompt/{fastfetch,starship}.nix`.

**Interface:** Preserve `<shell/packages>` and its `dev`/`personal` providers, `<shell/utils>`, `<shell/my-scripts>`, `<shell/fastfetch>`, and `<shell/starship>`.

- [x] Move the complete `packages` aspect, including its base NixOS package list and `provides`, into `profiles.nix`. Keep package order and the existing personal Darwin service configuration.
- [x] Move `utils` into `utilities.nix` and script packaging into `scripts.nix`. Keep the two source scripts under repository `scripts/` and read them through `paths.scripts`.
- [x] Move Fastfetch and Starship into their named files. Keep Starship's custom multiline TOML handling and jj-starship packaging intact. A cohesive Starship file above 200 lines is permitted.
- [ ] Evaluate affected Home Manager derivations and compare package lists, utility enable flags, Starship generated text, and script runtimeInputs with baseline.
- [ ] Run formatting, API comparison, and diff review. Suggested description: `refactor: organize package profiles and prompt configuration`.

## Task 7: Split terminal workspace modules

**Files:** Replace `modules/shell/terminal-multiplexer.nix` with `modules/shell/multiplexer/{herdr,workmux,tmux,zellij}.nix`; update `nix/checks/herdr-plugins.nix` only for stable source references if not already covered by Task 2.

**Interface:** Preserve `<shell/herdr>`, `<shell/workmux>`, `<shell/tmux>`, and `<shell/zellij>`; retain reconciler script path for existing tests.

- [x] Extract each complete aspect without changing activation ordering, completion generation, terminal commands, or configuration deployment lists.
- [x] Herdr imports its builder with `import (paths.root + "/lib/shell/herdr-plugins.nix") { inherit inputs lib pkgs; }`. Read its script using `builtins.readFile (paths.root + "/modules/shell/herdr-plugin-reconcile.sh")`.
- [x] Keep Tmux's picker script, all five status styles, and each explicit native file mapping. Do not replace explicit files with blanket directory deployment.
- [ ] Run `bash tests/herdr-plugin-reconcile.sh` and `nix build --no-link --no-update-lock-file .#checks.x86_64-linux.herdr-plugin-reconcile`.
- [ ] Compare Herdr activation text/manifest, completion outputs, Tmux/Zellij settings, and package selections with baseline; evaluate affected host Home Manager outputs and run formatting.
- [ ] Review the API ledger and diff. Suggested description: `refactor: separate terminal workspace aspects`.

## Task 8: Split applications and system/desktop modules

**Files:** Create the application, system/desktop, system/boot, and desktop/quickshell destinations listed in the file map; remove only their replaced grouped files.

**Interface:** Preserve all original application and system aspects, `<desktop/qs>`, `<desktop/qs/noctalia>`, and `<desktop/qs/dms>`.

- [x] Extract each complete browser/editor/terminal aspect. Preserve Zen's schema version and activation guard, Zed's static/dynamic settings assembly, and Ghostty/Wezterm source-plus-inline configuration behavior.
- [x] Extract fonts and XDG into their named files. Keep XDG portal service ordering overrides and MIME/user-directory settings together.
- [x] Extract bootloaders and impermanence into their named files. Keep all bootloader provider paths and installer-profile selection unchanged.
- [x] Preserve Quickshell's base once, in `noctalia.nix`, alongside its provider. Its outer structure becomes:

```nix
{
  den.aspects.desktop._.qs.nixos = { pkgs, ... }: {
    environment.systemPackages = with pkgs; [ quickshell ];
  };
  # Assign the existing complete Noctalia provider to:
  # den.aspects.desktop._.qs.provides.noctalia
}
```

In `dms.nix`, assign the existing complete DMS provider to `den.aspects.desktop._.qs.provides.dms`. Retain each provider's existing includes; discovering the Noctalia file must not implicitly enable Noctalia when selecting DMS.

- [ ] After the application split, then after the system/desktop split, run formatting and the relevant host matrix. Compare service settings, native file destinations, application settings, boot options, and persistence entries with baseline.
- [ ] Review each category independently and record local descriptions: `refactor: organize application modules` and `refactor: separate boot and desktop concerns`.

## Task 9: Extract SOPS builders and host providers

**Files:** Replace `modules/secrets/sops.nix` with `modules/secrets/sops/{base,vps,esquire,acerus,mbp}.nix`; create `lib/secrets/sops/builders.nix`.

**Interface:** `import builders.nix { inherit lib inputs paths; }` returns `{ mkHomeManagerSops; mkNixosSops; mkDarwinSops; sharedSopsFile; hostSopsFile; }`. Each builder retains its existing argument defaults and module-returning function shape.

- [x] Move all existing helper bindings from the original `let` into the builder file. Keep internal runtime-secret names, package helpers, `recursiveUpdate`, and `optionalAttrs` semantics. Export only the six names above.
- [x] `base.nix` declares only the original base Home Manager SOPS configuration, including shared secrets and session variables.
- [x] Each provider file imports the builders it needs and declares its existing provider with the original name. For example:

```nix
{ __findFile, lib, inputs, paths, constants, ... }:
let
  inherit (import (paths.root + "/lib/secrets/sops/builders.nix") {
    inherit lib inputs paths;
  }) mkNixosSops hostSopsFile;
in
{
  den.aspects.secrets._.sops.provides.vps = {
    includes = [ <secrets/sops> ];
    nixos = mkNixosSops {
      defaultSopsFile = hostSopsFile.vps;
      secrets."passwords/${constants.user.admin.username}".neededForUsers = true;
    };
  };
}
```

- [x] Copy Esquire, Acerus, and MBP provider bodies verbatim apart from helper wiring. Retain MBP's NixOS branch as well as its Darwin branch; being unused on the current host is not grounds for deletion. Host-specific data stays in those named provider aspects.
- [ ] Compare SOPS secret names, files, owners, modes, paths, `neededForUsers`, age settings, shared includes, and generated template metadata/content against baseline for all hosts. Do not decrypt encrypted YAML.
- [ ] Run the full host evaluation matrix and formatting. Recheck encrypted payload hashes and API ledger. Suggested description: `refactor: separate SOPS builders and host providers`.

## Task 10: Document navigation and native asset status

**Files:** Modify `README.md`; create `dots/README.md`. Existing native payload files and historical specs/plans remain untouched.

**Interface:** Status inventory columns are `Path`, `Status`, `Consumer / aspect`, and `Notes`. Status describes a file's wiring, not whether every host enables its aspect.

- [x] Enumerate native assets with `rg --files dots`; trace each app subtree through `source`, `readFile`, generated text, and recursive directory deployment. Record exceptions at file level where a subtree mixes wired and dormant files.
- [x] Use the following distinction in the inventory:

| Path | Status | Consumer / aspect | Notes |
| --- | --- | --- | --- |
| `config/atuin/config.toml` | dormant, if the baseline reference audit confirms it | none | Atuin may still be enabled inline under `<shell/utils>` |
| `config/fish/conf.d/atuin.fish` | active | `modules/shell/shells/fish.nix`, `<shell/fish>` | This is shell integration, separate from the native Atuin config |

Apply the same evidence standard to Sesh, Niri, Swaylock, XDG portal, templates, themes, and copied plugins. Mark `manual` only when existing documentation or wiring establishes manual deployment; lack of a reference alone means dormant.

- [x] Update the root tree and placement rules: public aspects in technical categories, generators/builders in `lib/`, stable asset paths, preserved Den names, scoped directory deployment, and the status inventory link.
- [x] Document physical examples such as `modules/shell/multiplexer/tmux.nix -> <shell/tmux> -> dots/config/tmux/` so readers can find both wiring and native settings.
- [x] Check all relative Markdown links resolve and compare pre-existing native payload hashes. Only `dots/README.md` should be new under `dots/`. Suggested description: `docs: explain category layout and native configuration status`.

## Task 11: Final integration review and handoff

**Files:** Review all changed files. No additional functionality is introduced.

**Interface:** Produces a verified structural migration and a report separating passed checks, existing configuration failures, and environment-blocked checks.

- [x] Compare the expanded public API ledger and sorted host/user include inventory. Account explicitly for base aspects and nested providers. Review duplicate *field* ownership rather than rejecting intentional provider extensions of a shared parent.
- [x] Check stable-path coverage:

```bash
rg -n '(\.\./)+(dots|scripts|secrets)' modules lib nix --glob '*.nix'
rg -n 'shells\.nix|terminal-multiplexer\.nix|llm-agents\.nix|desktop-support\.nix|secrets/sops\.nix' modules lib nix tests README.md dots/README.md
```

Expected: asset-root literals only in the central path definition; no obsolete active references. Old paths in historical specs/plans are intentionally retained.

- [x] Check file nesting and sizes with `rg --files modules lib nix` and `wc -l` on changed files. Explain cohesive oversized files rather than introducing extraction churn solely for a threshold.
- [ ] Regenerate `flake.nix`; compare it and `flake.lock` with baseline. Run `just fmt-check`, both shell tests, `nix flake check --no-update-lock-file --accept-flake-config --print-build-logs`, and the complete host/Home Manager matrix.
- [ ] Compare target settings and generated strings where derivations changed. Distinguish flake source path changes from changed runtime content. Verify native payload and encrypted YAML hashes remain identical.
- [ ] Review the local diff for altered strings, ordering, `mkIf`/`mkBefore`/`mkAfter`/`mkOrder`, renamed aspects, widened imports, and changed deployment scope. Remove only implementation-created temporary artifacts from tracked changes.
- [ ] Report changed category locations, exact checks and outcomes, any outstanding platform/build restrictions, and local version-control status. Never describe blocked evaluation as passing.

## Completion criteria

All eleven tasks are reviewed; the exact public interface and host/user composition are preserved; documentation identifies active versus retained native configuration; generated flake and lock content remain unchanged; runtime checks pass or have explicit unresolved limitations. Planning completion alone does not mean the refactor has been implemented or evaluated.

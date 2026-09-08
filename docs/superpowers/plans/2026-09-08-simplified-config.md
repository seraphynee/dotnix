# Simplified Dendritic Configuration Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Reduce unused flake inputs and repeated Den composition while preserving every existing host/user capability and preferring the newest usable packages.

**Architecture:** Keep atomic Den aspects as implementation units, then compose shared behavior through the platform-neutral `<profile/workstation>` role and the user-facing `<feature/development>` capability. Retain dedicated package inputs when they are newer, unavailable in nixpkgs, or provide required modules/sources; remove only audited inputs without consumers.

**Tech Stack:** Nix Flakes, NixOS, nix-darwin, Home Manager, Den, flake-parts, `flake-file`, treefmt, Bash checks, SOPS-Nix.

**Spec:** `docs/superpowers/specs/2026-09-08-simplified-config-design.md`

## Global Constraints

- Keep Den, `flake-file`, and the dendritic composition model.
- Prefer the newest usable package when choosing between a dedicated input and pinned `nixpkgs`.
- Preserve effective configuration for every existing host and user.
- Keep storage, boot, hardware, and secret policy explicit in host files.
- Use only modern, flake-first Nix commands.
- Do not modify any file under `secrets/`.
- Do not resolve the unrelated FZF/Atuin Ctrl-R behavior warning.
- Do not interact with any upstream repository.
- This managed checkout has no `.jj` workspace; use Git only for local task commits and never push.
- Edit input declarations under `nix/inputs/`; regenerate `flake.nix` through `nix run .#write-flake`.

---

### Task 1: Add profile-composition characterization coverage

**Files:**
- Create: `nix/checks/profile-composition.nix`

**Interfaces:**
- Consumes: `self.nixosConfigurations.{acerus,esquire}` and their Home Manager users.
- Produces: `checks.<system>.profile-composition`, a derivation guarded by assertions for shared and host-specific behavior.

- [ ] **Step 1: Add characterization assertions before moving any includes**

Create `nix/checks/profile-composition.nix`:

```nix
{
  lib,
  self,
  ...
}:
{
  perSystem =
    { pkgs, ... }:
    let
      acerus = self.nixosConfigurations.acerus.config;
      esquire = self.nixosConfigurations.esquire.config;
      workstations = [
        acerus
        esquire
      ];
      workstationHomes = map (config: config.home-manager.users.seraphynee) workstations;
      allWorkstations = predicate: lib.all predicate workstations;
      allWorkstationHomes = predicate: lib.all predicate workstationHomes;
      hasPath = path: config: lib.attrByPath path false config;
    in
    {
      checks.profile-composition =
        assert allWorkstations (config: config.programs.mango.enable);
        assert allWorkstationHomes (home: home.programs.noctalia.enable);
        assert allWorkstations (config: config.services.tailscale.enable);
        assert
          allWorkstations (
            config: lib.elem "multi-user.target" (config.systemd.services.kanata.wantedBy or [ ])
          );
        assert allWorkstations (config: config.services.openssh.enable);
        assert allWorkstations (config: config.virtualisation.incus.enable);
        assert allWorkstationHomes (home: home.programs.fish.enable);
        assert allWorkstationHomes (home: home.programs.zsh.enable);
        assert allWorkstationHomes (home: home.programs.neovim.enable);
        assert allWorkstationHomes (home: home.programs.atuin.enable);
        assert allWorkstationHomes (home: home.programs.direnv.enable);
        assert acerus.services.cloudflare-warp.enable;
        assert !(esquire.services.cloudflare-warp.enable or false);
        assert esquire.virtualisation.podman.enable;
        assert !acerus.virtualisation.podman.enable;
        assert hasPath [ "services" "handy" "enable" ] (acerus.home-manager.users.seraphynee);
        assert !(hasPath [ "services" "handy" "enable" ] (esquire.home-manager.users.seraphynee));
        pkgs.runCommand "profile-composition" { } ''
          touch "$out"
        '';
    };
}
```

- [ ] **Step 2: Run the new check against the pre-refactor configuration**

Run:

```bash
nix build .#checks.x86_64-linux.profile-composition --accept-flake-config --no-link
```

Expected: the derivation builds successfully. If an assertion does not match the current effective configuration, inspect the evaluated option and correct the assertion to characterize reality; do not change production configuration in this task.

- [ ] **Step 3: Run the existing evaluation suite**

Run:

```bash
nix flake check --no-build --accept-flake-config
```

Expected: success, including evaluation of `profile-composition`; the pre-existing FZF/Atuin warning may remain.

- [ ] **Step 4: Commit the characterization check locally**

```bash
git add nix/checks/profile-composition.nix
git commit -m "test: characterize shared workstation profiles"
```

---

### Task 2: Compose repeated includes as Den profile and feature aspects

**Files:**
- Create: `modules/profiles.nix`
- Modify: `modules/hosts/acerus.nix`
- Modify: `modules/hosts/esquire.nix`
- Modify: `modules/users/seraphynee.nix`
- Modify: `modules/users/micha.nix`
- Test: `nix/checks/profile-composition.nix`

**Interfaces:**
- Produces: `<profile/workstation>` and `<feature/development>` Den include targets.
- Consumes: existing atomic aspects; no atomic aspect behavior changes.
- Preserves: all assertions introduced in Task 1.

- [ ] **Step 1: Confirm the characterization check passes immediately before composition changes**

Run:

```bash
nix build .#checks.x86_64-linux.profile-composition --accept-flake-config --no-link
```

Expected: PASS.

- [ ] **Step 2: Create the two composition aspects**

Create `modules/profiles.nix`:

```nix
{ __findFile, ... }:
{
  den.aspects.profile._.workstation = {
    description = "Shared workstation system, desktop, application, and service capabilities";

    includes = [
      <system/audio>
      <system/fonts>
      <system/locale>
      <system/networking>
      <system/settings>
      <system/ssh>
      <system/sshd>
      <system/virt>
      <system/xdg>

      <desktop/wm/mango>
      <desktop/qs/noctalia>

      <apps/chromium>
      <apps/discord>
      <apps/firefox>
      <apps/ghostty>
      <apps/wezterm>
      <apps/zed>
      <apps/zen>

      <services/kanata>
      <services/tailscale>
    ];
  };

  den.aspects.feature._.development = {
    description = "Shared interactive development environment";

    includes = [
      <shell/packages/dev>
      <shell/packages/personal>
      <shell/nix-tools>

      <shell/_1password>
      <shell/ai>
      <shell/bash>
      <shell/env>
      <shell/fish>
      <shell/lazygit>
      <shell/neovim>
      <shell/nh>
      <shell/starship>
      <shell/tmux>
      <shell/utils>
      <shell/zsh>
    ];
  };
}
```

- [ ] **Step 3: Replace the shared Acerus includes with the workstation profile**

In `mkAcerusAspect`, keep the storage, boot, and persistence block first; replace the common system/desktop/app/service includes with this exact shorter list:

```nix
includes = [
  <disko/btrfs-luks>
  bootloader
  <system/impermanence>

  <profile/workstation>

  <system/bluetooth>
  <apps/handy>
  <services/cloudflare-warp>

  <secrets/sops/acerus>
];
```

- [ ] **Step 4: Replace the shared Esquire includes with the workstation profile**

In `mkEsquireAspect`, use:

```nix
includes = [
  <disko/btrfs-luks>
  bootloader
  <system/impermanence>

  <profile/workstation>

  <system/nvidia>
  <system/podman>
  <apps/datagrip>
  <apps/vscode>

  <secrets/sops/esquire>
];
```

- [ ] **Step 5: Replace the common Seraphynee user includes with the development feature**

Keep Den routing, primary-user selection, and Fish shell selection. Replace the duplicated development includes with `<feature/development>`, then retain only Seraphynee-specific additions:

```nix
includes = [
  <den/host-aspects>
  <den/primary-user>

  (<den/user-shell> "fish")
  <feature/development>

  <shell/espanso>
  <shell/fastfetch>
  <shell/formatters>
  <shell/vcs>
  <shell/helix>
  <shell/herdr>
  <shell/hunk>
  <shell/lla>
  <shell/llm_agents>
  <shell/my-scripts>
  <shell/nano>
  <shell/ocr>
  <shell/opencommit>
  <shell/pet>
  <shell/superfile>
  <shell/television>
  <shell/workmux>
  <shell/worktrunk>
  <shell/yazi>
  <shell/zellij>
];
```

The temporary `<shell/llm_agents>` spelling is intentional in this task; Task 3 renames it independently.

- [ ] **Step 6: Reduce Micha to the development feature and shell selection**

Use:

```nix
includes = [
  <den/host-aspects>
  (<den/user-shell> "zsh")
  <feature/development>
];
```

- [ ] **Step 7: Re-run composition and full evaluation checks**

Run:

```bash
nix build .#checks.x86_64-linux.profile-composition --accept-flake-config --no-link
nix flake check --no-build --accept-flake-config
```

Expected: both commands pass with the same characterized capabilities.

- [ ] **Step 8: Review the include-list delta for accidental behavior movement**

Run:

```bash
git diff -- modules/profiles.nix modules/hosts/acerus.nix modules/hosts/esquire.nix modules/users/seraphynee.nix modules/users/micha.nix
```

Expected: every removed host/user include appears exactly once in the matching profile or feature, except explicitly retained host/user additions.

- [ ] **Step 9: Commit the composition refactor locally**

```bash
git add modules/profiles.nix modules/hosts/acerus.nix modules/hosts/esquire.nix modules/users/seraphynee.nix modules/users/micha.nix
git commit -m "refactor: compose workstation and development aspects"
```

---

### Task 3: Normalize names and remove deprecated or redundant Nix syntax

**Files:**
- Modify: `nix/constants.nix`
- Modify: `nix/checks/vcs-identity.nix`
- Modify: `modules/users/chianyung.nix`
- Modify: `modules/users/seraphynee.nix`
- Modify: `modules/shell/ai/agents.nix`
- Modify: `modules/shell/multiplexer/workmux.nix`
- Modify: `modules/apps/browsers/zen.nix`
- Modify: `modules/system/platform.nix`
- Modify: `modules/hosts/acerus.nix`
- Modify: `modules/hosts/esquire.nix`

**Interfaces:**
- Renames: internal constant `git_user` to `gitUser`.
- Renames: Den include target `<shell/llm_agents>` to `<shell/llm-agents>`.
- Preserves: generated user identities, package selection, and platform branches.

- [ ] **Step 1: Record every old spelling and deprecated accessor**

Run:

```bash
rg -n 'git_user|llm_agents|stdenv\.(isDarwin|isLinux)|pkgs\.system|imports = \[ \];|with inputs; \[' --glob '*.nix' .
```

Expected: matches only in the files listed for this task.

- [ ] **Step 2: Rename the Git identity constant and all consumers**

Change every user record in `nix/constants.nix` from:

```nix
git_user = value;
```

to:

```nix
gitUser = value;
```

Update `modules/users/chianyung.nix`, `modules/users/seraphynee.nix`, and all expected constant attrsets and consumers in `nix/checks/vcs-identity.nix` to use `.gitUser` and `gitUser =`.

- [ ] **Step 3: Rename the LLM agent aspect**

In `modules/shell/ai/agents.nix`, change:

```nix
den.aspects.shell._.llm_agents =
```

to:

```nix
den.aspects.shell._."llm-agents" =
```

In `modules/users/seraphynee.nix`, change the include to:

```nix
<shell/llm-agents>
```

- [ ] **Step 4: Replace deprecated platform accessors**

Make these exact semantic substitutions:

```nix
pkgs.stdenv.isDarwin
```

becomes:

```nix
pkgs.stdenv.hostPlatform.isDarwin
```

and:

```nix
pkgs.stdenv.isLinux
```

becomes:

```nix
pkgs.stdenv.hostPlatform.isLinux
```

Apply them in `nix/checks/vcs-identity.nix` and `modules/apps/browsers/zen.nix`. In `modules/shell/multiplexer/workmux.nix`, replace `${pkgs.system}` with `${pkgs.stdenv.hostPlatform.system}`.

- [ ] **Step 5: Remove redundant syntax**

Delete `imports = [ ];` from the NixOS bodies in `modules/hosts/acerus.nix` and `modules/hosts/esquire.nix`. In `modules/system/platform.nix`, replace:

```nix
imports = with inputs; [ inputs.nixos-wsl.nixosModules.wsl ];
```

with:

```nix
imports = [ inputs.nixos-wsl.nixosModules.wsl ];
```

- [ ] **Step 6: Verify old patterns are gone**

Run:

```bash
rg -n 'git_user|llm_agents|stdenv\.(isDarwin|isLinux)|pkgs\.system|imports = \[ \];|with inputs; \[' --glob '*.nix' .
```

Expected: no matches.

- [ ] **Step 7: Run identity, composition, and evaluation checks**

Run:

```bash
nix build .#checks.x86_64-linux.vcs-identity --accept-flake-config --no-link
nix build .#checks.x86_64-linux.profile-composition --accept-flake-config --no-link
nix flake check --no-build --accept-flake-config
```

Expected: all pass. Repository-originated deprecation warnings addressed by this task should be absent; the FZF/Atuin warning may remain.

- [ ] **Step 8: Commit the naming and syntax cleanup locally**

```bash
git add nix/constants.nix nix/checks/vcs-identity.nix modules/users/chianyung.nix modules/users/seraphynee.nix modules/shell/ai/agents.nix modules/shell/multiplexer/workmux.nix modules/apps/browsers/zen.nix modules/system/platform.nix modules/hosts/acerus.nix modules/hosts/esquire.nix
git commit -m "refactor: normalize dendritic configuration names"
```

---

### Task 4: Separate Jujutsu command aliases from core VCS configuration

**Files:**
- Create: `lib/shell/vcs/jujutsu-aliases.nix`
- Modify: `lib/shell/vcs/jujutsu.nix`
- Modify: `nix/checks/vcs-identity.nix`

**Interfaces:**
- Produces: `jujutsu-aliases.nix`, a dependency-free Nix expression returning the complete `programs.jujutsu.settings.aliases` attrset.
- Consumes: the helper through `import ./jujutsu-aliases.nix`.
- Preserves: every existing alias key and argument list byte-for-byte.

- [ ] **Step 1: Extend the VCS characterization check for simple and scripted Jujutsu aliases**

Add these assertions before the `runCommand` in `nix/checks/vcs-identity.nix`:

```nix
assert seraphyne.config.programs.jujutsu.settings.aliases.ed == [ "edit" ];
assert seraphyne.config.programs.jujutsu.settings.aliases.fetch == [
  "git"
  "fetch"
];
assert builtins.elem "workspace" seraphyne.config.programs.jujutsu.settings.aliases.wacd;
assert builtins.elem "workspace" seraphyne.config.programs.jujutsu.settings.aliases.wd;
```

- [ ] **Step 2: Run the enhanced check before extracting the aliases**

Run:

```bash
nix build .#checks.x86_64-linux.vcs-identity --accept-flake-config --no-link
```

Expected: PASS, proving the assertions describe the current alias registry.

- [ ] **Step 3: Move the alias registry into its focused helper**

Copy the complete attrset currently assigned to
`programs.jujutsu.settings.aliases`—from `ed = [ "edit" ];` through the closing
`wd` entry—without modifying any key, string, command, ordering, or shell body.
Make that attrset the entire return value of
`lib/shell/vcs/jujutsu-aliases.nix`:

```nix
{
  ed = [ "edit" ];
  la = [
    "log"
    "-r"
    "all()"
  ];
  abd = [ "abandon" ];
  fetch = [
    "git"
    "fetch"
  ];
  init = [
    "git"
    "init"
    "--colocate"
  ];
  # Hack when waiting for https://github.com/jj-vcs/jj/issues/405
  # pre-committed commit
  pco = [
    "util"
    "exec"
    "--"
    "bash"
    "-c"
    ''
      set -euo pipefail

      # List files changed in the current working commit (`@`)
      changed_files=$(jj diff --name-only -r @)

      # If nothing changed, just commit normally
      if [ -z "$changed_files" ]; then
        exec jj commit "$@"
      fi

      # Run pre-commit only on the changed files
      printf '%s\n' "$changed_files" | xargs pre-commit run --files

      # If pre-commit succeeded, create the commit
      exec jj commit "$@"
    ''
    ""
  ];

  # Run pre-commit before editing the current commit description
  pde = [
    "util"
    "exec"
    "--"
    "bash"
    "-c"
    ''
      set -euo pipefail

      # List files changed in the current working commit (`@`)
      changed_files=$(jj diff --name-only -r @)

      # If nothing changed, just edit the current commit description
      if [ -z "$changed_files" ]; then
        exec jj describe --editor "$@"
      fi

      # Run pre-commit only on the changed files
      printf '%s\n' "$changed_files" | xargs pre-commit run --files

      # If pre-commit succeeded, edit the current commit description
      exec jj describe --editor "$@"
    ''
    ""
  ];
  mark = [
    "bookmark"
    "set"
    "-r"
  ];
  markc = [
    "bookmark"
    "set"
    "-r"
    "@"
  ];
  push = [
    "git"
    "push"
    "--allow-new"
  ];
  track = [
    "bookmark"
    "track"
  ];
  wl = [
    "workspace"
    "list"
  ];
  wa = [
    "util"
    "exec"
    "--"
    "bash"
    "-c"
    ''
      set -euo pipefail
      root=$(jj workspace root)
      base=$(basename "$root")
      name="$base.$0"
      dest="$(dirname "$root")/$name"
      jj workspace add --name "$name" --revision main "$dest"
    ''
  ];
  wacd = [
    "util"
    "exec"
    "--"
    "bash"
    "-c"
    ''
      set -euo pipefail
      arg="$0"
      if [ -z "$arg" ]; then
        echo "usage: jj wacd <workspace>" >&2
        exit 2
      fi
      root=$(jj workspace root)
      base=$(basename "$root")
      name="$base.$arg"
      dest="$(dirname "$root")/$name"
      jj workspace add --name "$name" --revision main "$dest" 1>&2
      printf '%s\n' "$dest"
    ''
  ];
  wq = [
    "util"
    "exec"
    "--"
    "bash"
    "-c"
    ''
      set -euo pipefail
      root=$(jj workspace root)
      repo="$root/.jj/repo"
      if [ -f "$repo" ]; then
        repo_ref=$(cat "$repo")
        shared_repo=$(cd "$root/.jj" && cd "$repo_ref" && pwd -P)
        root=$(dirname "$(dirname "$shared_repo")")
      fi
      printf '%s\n' "$root"
    ''
  ];
  wcd = [
    "util"
    "exec"
    "--"
    "bash"
    "-c"
    ''
      set -euo pipefail
      arg="$0"
      if [ -z "$arg" ]; then
        echo "usage: jj wcd <workspace>" >&2
        exit 2
      fi
      if dest=$(jj workspace root --name "$arg" 2>/dev/null); then
        printf '%s\n' "$dest"
      else
        root=$(jj wq)
        base=$(basename "$root")
        jj workspace root --name "$base.$arg"
      fi
    ''
  ];
  wd = [
    "util"
    "exec"
    "--"
    "bash"
    "-c"
    ''
      set -euo pipefail
      arg="$0"
      if dest=$(jj workspace root --name "$arg" 2>/dev/null); then
        name="$arg"
      else
        root=$(jj workspace root --name default 2>/dev/null || jj workspace root)
        base=$(basename "$root")
        name="$base.$arg"
        dest=$(jj workspace root --name "$name")
      fi
      if [ "$name" = "default" ]; then
        echo "refusing to forget/delete the default workspace" >&2
        exit 1
      fi
      jj workspace forget "$name"
      rm -rf -- "$dest"
      echo "Forgot and deleted workspace: $name ($dest)"
    ''
  ];
}
```

- [ ] **Step 4: Import the extracted registry from the core module**

Add this binding to the outer `let` in `lib/shell/vcs/jujutsu.nix`:

```nix
jujutsuAliases = import ./jujutsu-aliases.nix;
```

Replace the original inline alias attrset with:

```nix
aliases = jujutsuAliases;
```

- [ ] **Step 5: Verify the helper is data-only and behavior is preserved**

Run:

```bash
nix eval --json --file lib/shell/vcs/jujutsu-aliases.nix
nix build .#checks.x86_64-linux.vcs-identity --accept-flake-config --no-link
nix flake check --no-build --accept-flake-config
```

Expected: the first command returns the alias attrset as JSON; both checks pass.

- [ ] **Step 6: Review the extraction diff**

Run:

```bash
git diff --word-diff=porcelain -- lib/shell/vcs/jujutsu.nix lib/shell/vcs/jujutsu-aliases.nix
```

Expected: the alias registry is relocated, the import binding is added, and no alias content changes.

- [ ] **Step 7: Commit the focused Jujutsu split locally**

```bash
git add lib/shell/vcs/jujutsu.nix lib/shell/vcs/jujutsu-aliases.nix nix/checks/vcs-identity.nix
git commit -m "refactor: separate jujutsu aliases"
```

---

### Task 5: Prune unused inputs and wire the retained newest DMS packages

**Files:**
- Modify: `nix/inputs/core.nix`
- Modify: `nix/inputs/desktop.nix`
- Modify: `nix/inputs/system.nix`
- Modify: `nix/inputs/tooling.nix`
- Modify: `modules/desktop/quickshell/dms.nix`
- Modify: `README.md`
- Regenerate: `flake.nix`
- Regenerate: `flake.lock`

**Interfaces:**
- Removes root inputs: `catppuccin`, `flake-aspects`, `helium`, `hjem`, `niri`, `noctalia-qs`, and `systems`.
- Preserves root inputs followed by consumers: notably `systems-linux`, `nixpkgs-lib`, and `brew-src`.
- Makes `<desktop/qs/dms>` consume the dedicated `dms-shell` and matching `quickshell` packages.

- [ ] **Step 1: Record the dependency baseline and confirm the removal targets have no input consumers**

Run:

```bash
jq '{rootInputs: (.nodes.root.inputs | length), totalNodes: (.nodes | length)}' flake.lock
rg -n 'inputs\.(catppuccin|flake-aspects|helium|hjem|niri|noctalia-qs|systems)([^A-Za-z0-9_-]|$)' --glob '*.nix' --glob '!flake.nix' .
```

Expected: counts are 47 root inputs and 104 total nodes; the consumer search returns no matches.

- [ ] **Step 2: Add a source-level regression assertion for removed inputs**

Extend `nix/checks/profile-composition.nix` with an outer `inputs` argument and this binding:

```nix
removedInputsAbsent = lib.all (name: !(builtins.hasAttr name inputs)) [
  "catppuccin"
  "flake-aspects"
  "helium"
  "hjem"
  "niri"
  "noctalia-qs"
  "systems"
];
```

Add this assertion before the check derivation:

```nix
assert removedInputsAbsent;
```

Before changing declarations, run:

```bash
nix build .#checks.x86_64-linux.profile-composition --accept-flake-config --no-link
```

Expected: FAIL because the seven inputs still exist. This proves the assertion detects the intended change.

- [ ] **Step 3: Remove only the audited declarations**

From `nix/inputs/core.nix`, delete the complete declarations for:

```text
flake-aspects
hjem
systems
```

From `nix/inputs/desktop.nix`, delete the complete declarations for:

```text
catppuccin
helium
niri
noctalia-qs
```

Do not remove or rename any other input.

- [ ] **Step 4: Wire the retained DMS input into its aspect**

Replace `modules/desktop/quickshell/dms.nix` with:

```nix
{
  __findFile,
  inputs,
  ...
}:
{
  den.aspects.desktop._.qs.provides.dms = {
    includes = [ <desktop/qs> ];

    nixos =
      { pkgs, ... }:
      let
        dmsPackages = inputs.dms.packages.${pkgs.stdenv.hostPlatform.system};
      in
      {
        programs.dms-shell = {
          enable = true;
          package = dmsPackages.dms-shell;
          quickshell.package = dmsPackages.quickshell;
        };
      };
  };
}
```

- [ ] **Step 5: Document the durable input policy and annotate retained exceptions**

Add this section to `README.md` after the generated-flake editing guidance:

```markdown
## Flake Input Policy

Prefer packages from the pinned `nixpkgs` when they provide the needed version
and integration. Keep a dedicated input when it is newer, supplies a required
NixOS/Home Manager module, is unavailable in `nixpkgs`, provides pinned source
content, or belongs to the Den/flake framework. Recompare package versions when
updating the lock file; an input should not remain merely because it existed
before.
```

Add short reason comments immediately before retained exceptional inputs:

- `desktop.nix`: module/newer comments for Handy, DMS, Noctalia, Mango; module/unavailable comment for Zen; module comment for Noctalia Greeter; unavailable comment for Msnap.
- `system.nix`: post-release/newer-source comment for nixos-anywhere; module/source comments are unnecessary for the self-explanatory platform modules.
- `tooling.nix`: unavailable comments for Momoi Say and Workmux; newer comments for Worktrunk and Hunk; post-release/newer-source comment for Herdr; package-set comment for `llm-agents`; source-only group comment for Herdr plugins.

Do not put audited version numbers in these comments.

- [ ] **Step 6: Regenerate the source-of-truth outputs**

Run:

```bash
nix run .#write-flake
nix flake lock
```

Expected: `flake.nix` loses exactly the seven root declarations and `flake.lock` prunes their now-unreachable nodes without updating retained input revisions.

- [ ] **Step 7: Verify the input regression assertion now passes**

Run:

```bash
nix build .#checks.x86_64-linux.profile-composition --accept-flake-config --no-link
```

Expected: PASS.

- [ ] **Step 8: Verify generated files and lock stability**

Run:

```bash
rg -n '^    (catppuccin|flake-aspects|helium|hjem|niri|noctalia-qs|systems)( =|\.)' flake.nix
jq -r '.nodes.root.inputs | keys[]' flake.lock | rg '^(catppuccin|flake-aspects|helium|hjem|niri|noctalia-qs|systems)$'
jq '{rootInputs: (.nodes.root.inputs | length), totalNodes: (.nodes | length)}' flake.lock
git diff -- flake.lock
```

Expected: both searches produce no matches; root input count is 40; total node count is lower than 104; retained root input revisions in the lock diff are unchanged.

- [ ] **Step 9: Run generated-flake and evaluation checks**

Run:

```bash
nix build .#checks.x86_64-linux.check-flake-file --accept-flake-config --no-link
nix flake check --no-build --accept-flake-config
```

Expected: both pass. The generated flake matches declarations and DMS evaluates with its retained input package set.

- [ ] **Step 10: Commit the dependency cleanup locally**

```bash
git add nix/inputs/core.nix nix/inputs/desktop.nix nix/inputs/system.nix nix/inputs/tooling.nix modules/desktop/quickshell/dms.nix nix/checks/profile-composition.nix README.md flake.nix flake.lock
git commit -m "refactor: prune unused flake inputs"
```

---

### Task 6: Run final repository verification and report the audit result

**Files:**
- Verify only; no production file is expected to change.

**Interfaces:**
- Consumes: all changes from Tasks 1–5.
- Produces: verification evidence, final input/node counts, and a clean local worktree.

- [ ] **Step 1: Run formatting and static analysis**

Run:

```bash
nix fmt -- --ci
```

Expected: all emitted files pass and zero files change.

- [ ] **Step 2: Run the full flake build/check suite**

Run:

```bash
nix flake check --accept-flake-config --print-build-logs
```

Expected: all checks build successfully. The explicitly deferred FZF/Atuin Ctrl-R warning may remain; warnings for deprecated `stdenv.isDarwin`, `stdenv.isLinux`, or `pkgs.system` from repository code must not remain.

- [ ] **Step 3: Confirm generated-flake consistency and dependency counts**

Run:

```bash
nix build .#checks.x86_64-linux.check-flake-file --accept-flake-config --no-link
jq '{rootInputs: (.nodes.root.inputs | length), totalNodes: (.nodes | length)}' flake.lock
```

Expected: generated-flake check passes, root input count is 40, and total nodes are fewer than the 104-node baseline.

- [ ] **Step 4: Confirm secrets and workspace hygiene**

Run:

```bash
git status --short
git diff --name-only HEAD -- secrets
git log --oneline -6
```

Expected: no uncommitted files, no secret-file changes, and local commits corresponding to the specification, plan, characterization, composition, naming cleanup, Jujutsu split, and input cleanup. Do not push.

- [ ] **Step 5: Prepare the completion report**

Report:

- the seven removed root inputs;
- retained dedicated inputs whose newer version or module/source role justified them;
- the final root-input and lock-node counts;
- the new `<profile/workstation>` and `<feature/development>` composition boundaries;
- the focused Jujutsu alias extraction and normalized names/platform accessors;
- exact verification commands and their results;
- the intentionally unchanged FZF/Atuin warning;
- confirmation that secrets and upstream repositories were untouched.

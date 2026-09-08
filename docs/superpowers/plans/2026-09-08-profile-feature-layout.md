# Profile and Feature Layout Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Split role profiles and user-facing features into namespace-matching directories and add a reusable, behavior-preserving server profile.

**Architecture:** Keep Den atomic aspects unchanged. Move `<profile/workstation>` and `<feature/development>` from the combined `modules/profiles.nix` file into focused namespace-matching files, add `<profile/server>` for the VPS locale/SSHD baseline, and retain disk, boot, networking, firewall, and secrets in the VPS host aspect.

**Tech Stack:** Nix Flakes, Den dendritic aspects, NixOS modules, flake-parts checks, treefmt

**Spec:** `docs/superpowers/specs/2026-09-08-simplified-config-design.md`

## Global Constraints

- Keep `den` and `flake-file`; the dendritic aspect model remains the configuration framework.
- Use `modules/profiles/workstation.nix`, `modules/profiles/server.nix`, and `modules/features/development.nix` so filesystem layout mirrors the Den namespaces.
- `<profile/server>` initially contains only `<system/locale>` and `<system/sshd>`.
- The VPS keeps `<disko/simple>`, `<system/bootloader/grub>`, networking/DHCP/firewall policy, and `<secrets/sops/vps>` in `modules/hosts/vps.nix`.
- Preserve the effective Acerus, Esquire, Seraphynee, Micha, and VPS configurations.
- Flakes-first only; use the modern Nix CLI and do not contact a Git upstream.
- Do not modify any file under `secrets/`.
- The existing FZF/Atuin Ctrl-R warning remains intentionally out of scope.

---

### Task 1: Characterize the VPS server baseline

**Files:**
- Modify: `nix/checks/profile-composition.nix`

**Interfaces:**
- Consumes: `self.nixosConfigurations.vps.config`.
- Produces: assertions proving the VPS locale and SSH server remain enabled before and after composition changes.

- [ ] **Step 1: Add the VPS configuration binding**

In the check's `let`, immediately after the Esquire binding, add:

```nix
vps = self.nixosConfigurations.vps.config;
```

- [ ] **Step 2: Add representative server assertions**

Immediately before the host-specific Acerus/Esquire assertions, add:

```nix
assert vps.i18n.defaultLocale == "en_US.UTF-8";
assert vps.services.openssh.enable;
```

These assertions characterize the two capabilities that will move behind
`<profile/server>`. Do not assert VPS disk, boot, networking, firewall, or
secret details because those do not move into the profile.

- [ ] **Step 3: Prove the characterization passes before refactoring**

Run:

```bash
nix build .#checks.x86_64-linux.profile-composition --accept-flake-config --no-link
```

Expected: PASS against the current direct `<system/locale>` and
`<system/sshd>` includes.

- [ ] **Step 4: Run repository evaluation**

Run:

```bash
nix flake check --no-build --accept-flake-config
```

Expected: PASS; the existing FZF/Atuin warning may remain.

- [ ] **Step 5: Commit the characterization**

```bash
git add nix/checks/profile-composition.nix
git commit -m "test: characterize server profile baseline"
```

---

### Task 2: Split profile and feature aspects by namespace

**Files:**
- Delete: `modules/profiles.nix`
- Create: `modules/profiles/workstation.nix`
- Create: `modules/profiles/server.nix`
- Create: `modules/features/development.nix`
- Modify: `modules/hosts/vps.nix`
- Test: `nix/checks/profile-composition.nix`

**Interfaces:**
- Produces: `<profile/workstation>` from `modules/profiles/workstation.nix`.
- Produces: `<profile/server>` from `modules/profiles/server.nix`.
- Produces: `<feature/development>` from `modules/features/development.nix`.
- Consumes: `<profile/server>` from the VPS host aspect.
- Preserves: every Task 1 characterization assertion and all existing workstation/development consumers.

- [ ] **Step 1: Move the workstation profile unchanged**

Create `modules/profiles/workstation.nix`:

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
}
```

- [ ] **Step 2: Move the development feature unchanged**

Create `modules/features/development.nix`:

```nix
{ __findFile, ... }:
{
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
    ];
  };
}
```

- [ ] **Step 3: Add the minimal server profile**

Create `modules/profiles/server.nix`:

```nix
{ __findFile, ... }:
{
  den.aspects.profile._.server = {
    description = "Shared server system capabilities";

    includes = [
      <system/locale>
      <system/sshd>
    ];
  };
}
```

- [ ] **Step 4: Consume the server profile from VPS**

Change the VPS include list to exactly:

```nix
includes = [
  <disko/simple>
  <system/bootloader/grub>

  <profile/server>

  <secrets/sops/vps>
];
```

Leave the existing `nixos` body unchanged so device selection, DHCP, firewall
enablement, and port 22 remain visibly host-specific.

- [ ] **Step 5: Remove the obsolete combined file**

Delete `modules/profiles.nix` after all three replacement aspect files exist.
Do not leave duplicate definitions in the import tree.

- [ ] **Step 6: Verify the filesystem and Den targets**

Run:

```bash
test ! -e modules/profiles.nix
test -f modules/profiles/workstation.nix
test -f modules/profiles/server.nix
test -f modules/features/development.nix
rg -n 'den\.aspects\.(profile|feature)' modules/profiles modules/features
```

Expected: exactly one definition each for `profile._.workstation`,
`profile._.server`, and `feature._.development`.

- [ ] **Step 7: Stage the migration for Git-backed flake evaluation**

```bash
git add modules/profiles.nix modules/profiles/workstation.nix modules/profiles/server.nix modules/features/development.nix modules/hosts/vps.nix
```

Expected: the deleted combined file and all new namespace files are visible to
the Git-backed flake source used by subsequent Nix commands.

- [ ] **Step 8: Verify behavior and formatting**

Run:

```bash
nix build .#checks.x86_64-linux.profile-composition --accept-flake-config --no-link
nix flake check --no-build --accept-flake-config
nix fmt -- --ci
```

Expected: all pass and the formatter changes zero files. The existing
FZF/Atuin warning may remain.

- [ ] **Step 9: Verify scope hygiene**

Run:

```bash
git diff --check
git diff --name-only HEAD -- secrets
git status --short
```

Expected: no whitespace errors, no secret changes, and only the five scoped
production paths are staged.

- [ ] **Step 10: Commit the layout migration**

```bash
git add modules/profiles.nix modules/profiles/workstation.nix modules/profiles/server.nix modules/features/development.nix modules/hosts/vps.nix
git commit -m "refactor: split profile and feature aspects"
```

---

### Task 3: Run final verification

**Files:**
- Verify only; no production file is expected to change.

**Interfaces:**
- Consumes: Tasks 1 and 2.
- Produces: final evidence for the namespace layout and unchanged effective configurations.

- [ ] **Step 1: Run the full build-producing suite**

```bash
nix flake check --accept-flake-config --print-build-logs
```

Expected: `all checks passed!`; the explicitly deferred FZF/Atuin warning may remain.

- [ ] **Step 2: Confirm clean final state**

```bash
git status --short
git diff --name-only 409a13e..HEAD -- secrets
git log --oneline -3
```

Expected: clean worktree, no secret changes, and commits for the approved
design revision, server characterization, and layout migration. Do not push.

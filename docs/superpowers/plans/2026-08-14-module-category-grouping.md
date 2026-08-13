# Module Category Grouping Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Reduce the physical Nix module tree from 81 files to 42 semantic category files without changing any Den aspect path or evaluated configuration.

**Architecture:** Related atomic Den aspects move into shared category files while retaining their exact left-hand-side attribute paths and independent enablement. Direct consolidation stays inside each current directory so relative paths remain stable; the existing `lib/shell/vcs/` helpers remain split behind `modules/shell/vcs.nix` to avoid a VCS megafile.

**Tech Stack:** Nix Flakes, vic/den, import-tree, NixOS, nix-darwin, Home Manager, sops-nix, treefmt, just, Jujutsu (`jj`).

## Global Constraints

- Use only modern Nix CLI commands and flake references; do not use `nix-shell`, `nix-env`, `nix-channel`, or other legacy channel workflows.
- Use `jj` for local version control and never contact the upstream repository.
- Do not use `git` as a fallback when `jj` is blocked by the execution environment.
- Preserve all existing Den aspect paths, including `<shell/llm_agents>`, and keep every aspect independently selectable.
- Preserve the exact existing left-hand-side `den.aspects` assignment spellings so the declaration checksum remains stable.
- Do not add category bundle aspects.
- Do not change package selections, settings, secrets, generated files, host includes, or user includes.
- Do not modify `dots/`, `secrets/`, `scripts/`, `modules/desktop`, `modules/disko`, `modules/hosts`, `modules/secrets`, `modules/users`, `nix`, or `lib`.
- Use `apply_patch` for repository edits and preserve unrelated working-copy changes.
- Keep direct merges in their current directory so `../../dots` references and `modules/shell/herdr-plugin-bootstrap.sh` remain valid.
- Treat a check that fails before the refactor as a baseline limitation; the final failure must match it and no additional failure is acceptable.

## File Structure

### Files created

- `modules/shell/packages.nix`: package profiles, configured foundational utilities, and local packaged scripts.
- `modules/shell/shells.nix`: Bash, Fish, Zsh, and shared runtime environment configuration.
- `modules/shell/prompt.nix`: Fastfetch and Starship.
- `modules/shell/editors.nix`: Helix, Nano, and Neovim.
- `modules/shell/terminal-workspaces.nix`: Herdr, tmux, and Zellij.
- `modules/shell/file-navigation.nix`: lla, Pet, Superfile, Television, and Yazi.
- `modules/shell/desktop-tools.nix`: Aerospace, Espanso, msnap, OCR, and Rift.
- `modules/apps/browsers.nix`: Chromium, Firefox, and Zen Browser.
- `modules/apps/editors.nix`: DataGrip, VS Code, and Zed.
- `modules/apps/terminals.nix`: Ghostty and WezTerm.
- `modules/system/hardware.nix`: audio, Bluetooth, NVIDIA, and TPM.
- `modules/system/boot.nix`: bootloader variants and impermanence.
- `modules/system/virtualization.nix`: Podman and libvirt/QEMU.
- `modules/system/desktop-support.nix`: fonts and XDG integration.
- `modules/system/platform.nix`: locale, operating-system settings, and WSL.
- `modules/services/networking.nix`: Cloudflare WARP and Tailscale.

### Files expanded in place

- `modules/shell/vcs.nix`: retain the Git/Jujutsu imports; add Hunk, Lazygit, OpenCommit, and Worktrunk.
- `modules/shell/llm-agents.nix`: retain generated agent configuration; add shared `.agents` deployment.
- `modules/shell/nix-tools.nix`: retain generic Nix tooling; add nh workflow configuration.
- `modules/system/networking.nix`: retain base networking; add SSH client/server aspects.

### Files intentionally retained

- `modules/shell/1password.nix`
- `modules/shell/homebrew.nix`
- `modules/apps/discord.nix`
- `modules/services/kanata.nix`

All other source files named in the tasks below are deleted after their assignments have been copied into the destination.

---

### Task 1: Record the structural and evaluation baseline

**Files:**

- Read: `docs/superpowers/specs/2026-08-14-module-category-grouping-design.md`
- Read: `modules/**/*.nix`
- Modify: none

**Interfaces:**

- Consumes: the pre-refactor module tree and current execution environment.
- Produces: exact expected counts/checksums and a recorded pass/fail baseline for later tasks.

- [ ] **Step 1: Confirm the approved design and working-copy state**

Run:

```bash
sed -n '1,240p' docs/superpowers/specs/2026-08-14-module-category-grouping-design.md
jj status
```

Expected: the design contains the 81-to-42 map. Preserve any user changes reported by `jj status`. In the managed Codex checkout, `jj status` may fail while snapshotting because its colocated Git object store is read-only; record that exact limitation and do not use Git as a fallback.

- [ ] **Step 2: Confirm the current file-count baseline**

Run:

```bash
test "$(find modules -name '*.nix' | wc -l)" -eq 81
test "$(find modules/shell -maxdepth 1 -name '*.nix' | wc -l)" -eq 36
test "$(find modules/apps -maxdepth 1 -name '*.nix' | wc -l)" -eq 9
test "$(find modules/system -maxdepth 1 -name '*.nix' | wc -l)" -eq 15
test "$(find modules/services -maxdepth 1 -name '*.nix' | wc -l)" -eq 3
```

Expected: PASS with exit status 0.

- [ ] **Step 3: Confirm the declaration and include inventories**

Run:

```bash
rg --no-filename -o 'den\.aspects\.[A-Za-z0-9_".-]+(\._\.[A-Za-z0-9_".-]+)*' modules -g '*.nix' | sort -u | sha256sum
rg --no-filename -o '<(apps|desktop|disko|lib|secrets|services|shell|system)/[^>]+>' modules -g '*.nix' | sort -u | sha256sum
```

Expected:

```text
724b9ab5d5da0deed8616fa5ffc9b4690feac39957433cfe3e860ecc69bf900a  -
c6b670417254854b118ff6a3f1afcd88994c0c350ad806a2948a1f33ea2caea0  -
```

The first checksum covers declared top-level aspect paths. The second covers every aspect path consumed through angle-bracket lookup.

- [ ] **Step 4: Run the desired-layout assertion and verify the red state**

Run:

```bash
test -f modules/shell/packages.nix \
  && test -f modules/apps/browsers.nix \
  && test -f modules/system/hardware.nix \
  && test -f modules/services/networking.nix \
  && test "$(find modules -name '*.nix' | wc -l)" -eq 42
```

Expected: FAIL because the destination category files do not exist yet.

- [ ] **Step 5: Run and record the current repository checks**

Run each command separately:

```bash
just treefmt-check
nix build 'path:.#checks.x86_64-linux.vcs-identity' --print-build-logs
nix flake check path:. --print-build-logs
just check
```

Expected in a normal local checkout: all commands pass. In the managed Codex checkout, Nix may report that access to `/nix/var/nix/daemon-socket/socket` is not permitted, and `just check` may also fail because the JJ workspace is not exposed as a standalone Git repository. Record the exact baseline messages for comparison in Task 6.

---

### Task 2: Consolidate shell aspects into semantic category files

**Files:**

- Create: `modules/shell/packages.nix`
- Create: `modules/shell/shells.nix`
- Create: `modules/shell/prompt.nix`
- Create: `modules/shell/editors.nix`
- Modify: `modules/shell/vcs.nix`
- Modify: `modules/shell/llm-agents.nix`
- Create: `modules/shell/terminal-workspaces.nix`
- Create: `modules/shell/file-navigation.nix`
- Modify: `modules/shell/nix-tools.nix`
- Create: `modules/shell/desktop-tools.nix`
- Retain unchanged: `modules/shell/1password.nix`
- Retain unchanged: `modules/shell/homebrew.nix`
- Delete after migration: every other replaced `modules/shell/*.nix` source listed in the steps.

**Interfaces:**

- Consumes: the 36 existing shell module files and `lib/shell/vcs/{profile,git,jujutsu}.nix`.
- Produces: 12 shell category files declaring the identical shell aspect paths with identical module values.

- [ ] **Step 1: Verify the shell layout is initially red**

Run:

```bash
test -f modules/shell/packages.nix \
  && test -f modules/shell/shells.nix \
  && test -f modules/shell/prompt.nix \
  && test -f modules/shell/editors.nix \
  && test -f modules/shell/terminal-workspaces.nix \
  && test -f modules/shell/file-navigation.nix \
  && test -f modules/shell/desktop-tools.nix \
  && test "$(find modules/shell -maxdepth 1 -name '*.nix' | wc -l)" -eq 12
```

Expected: FAIL.

- [ ] **Step 2: Build `packages.nix`**

Use `apply_patch` to move `modules/shell/00-packages.nix` to `modules/shell/packages.nix`. Keep its full `den.aspects.shell._.packages` assignment unchanged. Before the final closing brace, copy these complete assignments unchanged:

```text
modules/shell/utils.nix      -> den.aspects.shell._.utils.homeManager
modules/shell/my-scripts.nix -> den.aspects.shell._.my-scripts.homeManager
```

The destination keeps the outer argument header from `00-packages.nix`:

```nix
{ __findFile, inputs, ... }:
```

Add section comments `# Package profiles`, `# Configured utilities`, and `# Local scripts`. Delete `utils.nix` and `my-scripts.nix` only after their complete assignments are present.

- [ ] **Step 3: Build `shells.nix`**

Use `apply_patch` to create `modules/shell/shells.nix` with this outer header:

```nix
{ __findFile, lib, ... }:
```

Copy these complete assignments unchanged, in this order, under `# Bash`, `# Shared environment`, `# Fish`, and `# Zsh` comments:

```text
modules/shell/bash.nix -> den.aspects.shell._.bash
modules/shell/env.nix  -> den.aspects.shell._.env.homeManager
modules/shell/env.nix  -> den.aspects.shell._.env.nixos
modules/shell/fish.nix -> den.aspects.shell._.fish.homeManager
modules/shell/zsh.nix  -> den.aspects.shell._.zsh.homeManager
```

Delete `bash.nix`, `env.nix`, `fish.nix`, and `zsh.nix` after the assignments are present. Do not merge the Home Manager and NixOS halves of `<shell/env>` into a new value; retain their two exact dotted assignments.

- [ ] **Step 4: Build `prompt.nix`**

Use `apply_patch` to create the static attrset `modules/shell/prompt.nix`. Copy the complete `den.aspects.shell._.fastfetch` assignment from `fastfetch.nix`, followed by the complete `den.aspects.shell._.starship.homeManager` assignment from `starship.nix`. Add `# Fastfetch` and `# Starship` comments. Delete both source files.

- [ ] **Step 5: Build terminal `editors.nix`**

Use `apply_patch` to create `modules/shell/editors.nix` with this outer header:

```nix
{ lib, ... }:
```

Copy the complete Helix, Nano, and Neovim assignments unchanged and in alphabetical order:

```text
den.aspects.shell._.helix
den.aspects.shell._.nano.homeManager
den.aspects.shell._.neovim.homeManager
```

Delete `helix.nix`, `nano.nix`, and `neovim.nix`.

- [ ] **Step 6: Expand `vcs.nix`**

Change the outer form of `modules/shell/vcs.nix` to accept the exact union of outer arguments:

```nix
{
  __findFile,
  inputs,
  lib,
  ...
}:
```

Keep `den.aspects.shell._.vcs.homeManager.imports` and its three existing `lib/shell/vcs` paths unchanged. Copy the complete assignments below into the same output attrset under labeled sections:

```text
modules/shell/hunk.nix       -> den.aspects.shell._.hunk
modules/shell/lazygit.nix    -> den.aspects.shell._.lazygit.homeManager
modules/shell/opencommit.nix -> den.aspects.shell._.opencommit
modules/shell/worktrunk.nix  -> den.aspects.shell._.worktrunk
```

Delete the four source files. Do not move or edit anything under `lib/shell/vcs/`.

- [ ] **Step 7: Expand `llm-agents.nix`**

Keep the outer header, helper functions, generated configurations, and `den.aspects.shell._.llm_agents` value unchanged. Add the complete `den.aspects.shell._.ai` assignment from `ai.nix` to the final output attrset before the `llm_agents` assignment. Label it `# Shared agent instructions`. Delete `ai.nix`.

- [ ] **Step 8: Build `terminal-workspaces.nix`**

Use `apply_patch` to create `modules/shell/terminal-workspaces.nix` with this outer header:

```nix
{
  __findFile,
  inputs,
  lib,
  ...
}:
```

Copy the complete Herdr, tmux, and Zellij assignments unchanged and in that order. Keep `builtins.readFile ./herdr-plugin-bootstrap.sh` unchanged because the destination remains in `modules/shell`. Delete `herdr.nix`, `tmux.nix`, and `zellij.nix`; retain `herdr-plugin-bootstrap.sh`.

- [ ] **Step 9: Build `file-navigation.nix`**

Use `apply_patch` to create a static attrset containing the complete assignments from `lla.nix`, `pet.nix`, `superfile.nix`, `television.nix`, and `yazi.nix`, in that order. Preserve these exact assignment paths:

```text
den.aspects.shell._.lla.homeManager
den.aspects.shell._.pet.homeManager
den.aspects.shell._.superfile.homeManager
den.aspects.shell._.television.homeManager
den.aspects.shell._.yazi
```

Delete the five source files.

- [ ] **Step 10: Expand `nix-tools.nix`**

Keep the existing static attrset and full `den.aspects.shell._.nix-tools` assignment. Add the complete `den.aspects.shell._.nh.homeManager` assignment from `nh.nix`, under `# Rebuild workflow`. Delete `nh.nix`.

- [ ] **Step 11: Build `desktop-tools.nix`**

Use `apply_patch` to create `modules/shell/desktop-tools.nix` with this outer header:

```nix
{
  __findFile,
  inputs,
  lib,
  ...
}:
```

Copy the complete assignments from `aerospace.nix`, `espanso.nix`, `msnap.nix`, `ocr.nix`, and `rift.nix`, in that order. Delete those five source files.

- [ ] **Step 12: Format and run shell structural checks**

Run:

```bash
nix fmt
test "$(find modules/shell -maxdepth 1 -name '*.nix' | wc -l)" -eq 12
for dotnix_file in 1password desktop-tools editors file-navigation homebrew llm-agents nix-tools packages prompt shells terminal-workspaces vcs; do test -f "modules/shell/${dotnix_file}.nix"; done
rg --no-filename -o 'den\.aspects\.[A-Za-z0-9_".-]+(\._\.[A-Za-z0-9_".-]+)*' modules -g '*.nix' | sort -u | sha256sum
rg --no-filename -o '<(apps|desktop|disko|lib|secrets|services|shell|system)/[^>]+>' modules -g '*.nix' | sort -u | sha256sum
```

Expected: shell file count is 12, every category file exists, and the checksums remain:

```text
724b9ab5d5da0deed8616fa5ffc9b4690feac39957433cfe3e860ecc69bf900a  -
c6b670417254854b118ff6a3f1afcd88994c0c350ad806a2948a1f33ea2caea0  -
```

- [ ] **Step 13: Run focused Nix verification**

Run:

```bash
nix build 'path:.#checks.x86_64-linux.vcs-identity' --print-build-logs
nix eval 'path:.#nixosConfigurations.acerus.config.system.build.toplevel.drvPath' --raw
```

Expected: PASS, or the same Nix-daemon access failure recorded in Task 1.

- [ ] **Step 14: Create the local shell checkpoint**

Run:

```bash
jj diff --stat
jj commit -m "refactor(shell): group modules by category"
```

Expected: a local commit containing only shell-module relocations. If the managed checkout reports the read-only colocated object-store limitation recorded in Task 1, do not use Git; retain the changes in the working copy and continue.

---

### Task 3: Consolidate application aspects

**Files:**

- Create: `modules/apps/browsers.nix`
- Create: `modules/apps/editors.nix`
- Create: `modules/apps/terminals.nix`
- Retain unchanged: `modules/apps/discord.nix`
- Delete: `modules/apps/chromium.nix`, `modules/apps/firefox.nix`, `modules/apps/zen.nix`, `modules/apps/datagrip.nix`, `modules/apps/vscode.nix`, `modules/apps/zed.nix`, `modules/apps/ghostty.nix`, `modules/apps/wezterm.nix`

**Interfaces:**

- Consumes: nine independently selectable application aspects.
- Produces: four application files with all nine aspect values unchanged.

- [ ] **Step 1: Verify the application layout is initially red**

Run:

```bash
test -f modules/apps/browsers.nix \
  && test -f modules/apps/editors.nix \
  && test -f modules/apps/terminals.nix \
  && test "$(find modules/apps -maxdepth 1 -name '*.nix' | wc -l)" -eq 4
```

Expected: FAIL.

- [ ] **Step 2: Build `browsers.nix`**

Use `apply_patch` to create `modules/apps/browsers.nix` with this outer header:

```nix
{
  __findFile,
  inputs,
  ...
}:
```

Copy the complete Chromium, Firefox, and Zen assignments unchanged and in that order. Delete `chromium.nix`, `firefox.nix`, and `zen.nix`.

- [ ] **Step 3: Build graphical `editors.nix`**

Use `apply_patch` to create `modules/apps/editors.nix` with this outer header:

```nix
{ __findFile, ... }:
```

Copy the complete DataGrip, VS Code, and Zed assignments unchanged and in that order. Delete `datagrip.nix`, `vscode.nix`, and `zed.nix`.

- [ ] **Step 4: Build `terminals.nix`**

Use `apply_patch` to create a static attrset containing the complete `den.aspects.apps._.ghostty.homeManager` assignment followed by the complete `den.aspects.apps._.wezterm.homeManager` assignment. Delete `ghostty.nix` and `wezterm.nix`.

- [ ] **Step 5: Format and verify application structure**

Run:

```bash
nix fmt
test "$(find modules/apps -maxdepth 1 -name '*.nix' | wc -l)" -eq 4
for dotnix_file in browsers discord editors terminals; do test -f "modules/apps/${dotnix_file}.nix"; done
rg --no-filename -o 'den\.aspects\.[A-Za-z0-9_".-]+(\._\.[A-Za-z0-9_".-]+)*' modules -g '*.nix' | sort -u | sha256sum
```

Expected: four application files and declaration checksum `724b9ab5d5da0deed8616fa5ffc9b4690feac39957433cfe3e860ecc69bf900a`.

- [ ] **Step 6: Evaluate an application-rich host**

Run:

```bash
nix eval 'path:.#nixosConfigurations.esquire.config.system.build.toplevel.drvPath' --raw
```

Expected: PASS, or the same Nix-daemon access failure recorded in Task 1.

- [ ] **Step 7: Create the local application checkpoint**

Run:

```bash
jj diff --stat
jj commit -m "refactor(apps): group modules by category"
```

Expected: a local application-grouping commit, or the already-recorded read-only object-store limitation without a Git fallback.

---

### Task 4: Consolidate system aspects

**Files:**

- Create: `modules/system/hardware.nix`
- Create: `modules/system/boot.nix`
- Modify: `modules/system/networking.nix`
- Create: `modules/system/virtualization.nix`
- Create: `modules/system/desktop-support.nix`
- Create: `modules/system/platform.nix`
- Delete: the 14 replaced source files named in the steps; retain only the six destinations.

**Interfaces:**

- Consumes: 15 atomic system-aspect files.
- Produces: six system category files with the exact same aspect declarations and provided bootloader/SSH sub-aspects.

- [ ] **Step 1: Verify the system layout is initially red**

Run:

```bash
test -f modules/system/hardware.nix \
  && test -f modules/system/boot.nix \
  && test -f modules/system/virtualization.nix \
  && test -f modules/system/desktop-support.nix \
  && test -f modules/system/platform.nix \
  && test "$(find modules/system -maxdepth 1 -name '*.nix' | wc -l)" -eq 6
```

Expected: FAIL.

- [ ] **Step 2: Build `hardware.nix`**

Use `apply_patch` to create `modules/system/hardware.nix` with this outer header:

```nix
{ lib, ... }:
```

Copy the complete assignments from `audio.nix`, `bluetooth.nix`, `nvidia.nix`, and `tpm.nix`, in that order. Delete the four source files.

- [ ] **Step 3: Build `boot.nix`**

Use `apply_patch` to create `modules/system/boot.nix` with this outer header:

```nix
{
  __findFile,
  inputs,
  lib,
  ...
}:
```

Copy the complete `den.aspects.system._.bootloader` assignment, including its `grub`, `systemd-boot`, and `lanzaboote` providers, followed by the complete impermanence assignment. Delete `bootloader.nix` and `impermanence.nix`.

- [ ] **Step 4: Expand `networking.nix`**

Keep the existing static attrset and complete `den.aspects.system._.networking` assignment. Add the complete `den.aspects.system._.ssh` and `den.aspects.system._.sshd` assignments from `ssh.nix`, including the `forward-ports` provider. Delete `ssh.nix`.

- [ ] **Step 5: Build `virtualization.nix`**

Use `apply_patch` to create `modules/system/virtualization.nix` with this outer header:

```nix
{ constants, ... }:
```

Copy the complete Podman assignment followed by the complete `virt` assignment. Delete `podman.nix` and `virt.nix`.

- [ ] **Step 6: Build `desktop-support.nix`**

Use `apply_patch` to create `modules/system/desktop-support.nix` with this outer header:

```nix
{ ... }:
```

Copy the complete fonts assignment followed by the complete XDG assignment. Delete `fonts.nix` and `xdg.nix`.

- [ ] **Step 7: Build `platform.nix`**

Use `apply_patch` to create `modules/system/platform.nix` with this outer header:

```nix
{
  __findFile,
  constants,
  ...
}:
```

Copy the complete locale, settings, and WSL assignments unchanged and in that order. Delete `locale.nix`, `settings.nix`, and `wsl.nix`.

- [ ] **Step 8: Format and verify system structure**

Run:

```bash
nix fmt
test "$(find modules/system -maxdepth 1 -name '*.nix' | wc -l)" -eq 6
for dotnix_file in boot desktop-support hardware networking platform virtualization; do test -f "modules/system/${dotnix_file}.nix"; done
rg --no-filename -o 'den\.aspects\.[A-Za-z0-9_".-]+(\._\.[A-Za-z0-9_".-]+)*' modules -g '*.nix' | sort -u | sha256sum
rg --no-filename -o '<(apps|desktop|disko|lib|secrets|services|shell|system)/[^>]+>' modules -g '*.nix' | sort -u | sha256sum
```

Expected: six system files and the original declaration/include checksums.

- [ ] **Step 9: Evaluate system configurations**

Run each command separately:

```bash
nix eval 'path:.#nixosConfigurations.acerus.config.system.build.toplevel.drvPath' --raw
nix eval 'path:.#nixosConfigurations.esquire.config.system.build.toplevel.drvPath' --raw
nix eval 'path:.#nixosConfigurations.vps.config.system.build.toplevel.drvPath' --raw
nix eval 'path:.#darwinConfigurations.mbp.system' --raw
```

Expected: PASS for each available output, or the same environment limitation recorded in Task 1. A configuration-specific failure not present at baseline blocks this task and must be corrected before proceeding.

- [ ] **Step 10: Create the local system checkpoint**

Run:

```bash
jj diff --stat
jj commit -m "refactor(system): group modules by category"
```

Expected: a local system-grouping commit, or the already-recorded read-only object-store limitation without a Git fallback.

---

### Task 5: Consolidate network service aspects

**Files:**

- Create: `modules/services/networking.nix`
- Retain unchanged: `modules/services/kanata.nix`
- Delete: `modules/services/cloudflare-warp.nix`
- Delete: `modules/services/tailscale.nix`

**Interfaces:**

- Consumes: independent Cloudflare WARP and Tailscale aspects.
- Produces: one network-service category file plus the unchanged Kanata file.

- [ ] **Step 1: Verify the service layout is initially red**

Run:

```bash
test -f modules/services/networking.nix \
  && test "$(find modules/services -maxdepth 1 -name '*.nix' | wc -l)" -eq 2
```

Expected: FAIL.

- [ ] **Step 2: Build service `networking.nix`**

Use `apply_patch` to create a static attrset containing the complete `den.aspects.services._."cloudflare-warp".nixos` assignment followed by the complete `den.aspects.services._.tailscale.nixos` assignment. Add `# Cloudflare WARP` and `# Tailscale` comments. Delete `cloudflare-warp.nix` and `tailscale.nix`.

- [ ] **Step 3: Format and verify service structure**

Run:

```bash
nix fmt
test "$(find modules/services -maxdepth 1 -name '*.nix' | wc -l)" -eq 2
test -f modules/services/networking.nix
test -f modules/services/kanata.nix
rg --no-filename -o 'den\.aspects\.[A-Za-z0-9_".-]+(\._\.[A-Za-z0-9_".-]+)*' modules -g '*.nix' | sort -u | sha256sum
```

Expected: two service files and declaration checksum `724b9ab5d5da0deed8616fa5ffc9b4690feac39957433cfe3e860ecc69bf900a`.

- [ ] **Step 4: Evaluate a host using both network services**

Run:

```bash
nix eval 'path:.#nixosConfigurations.acerus.config.system.build.toplevel.drvPath' --raw
```

Expected: PASS, or the same Nix-daemon access failure recorded in Task 1.

- [ ] **Step 5: Create the local service checkpoint**

Run:

```bash
jj diff --stat
jj commit -m "refactor(services): group network modules"
```

Expected: a local service-grouping commit, or the already-recorded read-only object-store limitation without a Git fallback.

---

### Task 6: Verify the complete physical-only migration

**Files:**

- Verify: all files under `modules/`
- Verify unchanged: `dots/`, `secrets/`, `scripts/`, `modules/desktop`, `modules/disko`, `modules/hosts`, `modules/secrets`, `modules/users`, `nix`, `lib`
- Modify: only grouped Nix files if verification exposes a migration error

**Interfaces:**

- Consumes: the four completed domain migrations.
- Produces: a 42-file module tree with unchanged Den API, unchanged composition references, and verification evidence.

- [ ] **Step 1: Run the final desired-layout assertion**

Run:

```bash
test "$(find modules -name '*.nix' | wc -l)" -eq 42
test "$(find modules/shell -maxdepth 1 -name '*.nix' | wc -l)" -eq 12
test "$(find modules/apps -maxdepth 1 -name '*.nix' | wc -l)" -eq 4
test "$(find modules/system -maxdepth 1 -name '*.nix' | wc -l)" -eq 6
test "$(find modules/services -maxdepth 1 -name '*.nix' | wc -l)" -eq 2
```

Expected: PASS.

- [ ] **Step 2: Prove the declared and consumed aspect inventories are unchanged**

Run:

```bash
rg --no-filename -o 'den\.aspects\.[A-Za-z0-9_".-]+(\._\.[A-Za-z0-9_".-]+)*' modules -g '*.nix' | sort -u | sha256sum
rg --no-filename -o '<(apps|desktop|disko|lib|secrets|services|shell|system)/[^>]+>' modules -g '*.nix' | sort -u | sha256sum
```

Expected:

```text
724b9ab5d5da0deed8616fa5ffc9b4690feac39957433cfe3e860ecc69bf900a  -
c6b670417254854b118ff6a3f1afcd88994c0c350ad806a2948a1f33ea2caea0  -
```

- [ ] **Step 3: Confirm host and user includes were not edited**

Run:

```bash
jj diff --summary
rg -n '<(apps|services|shell|system)/[^>]+>' modules/hosts modules/users -g '*.nix'
```

Expected: `jj diff --summary` names only the design/plan documents and files under `modules/apps`, `modules/services`, `modules/shell`, and `modules/system`. The include search shows the original atomic aspect paths, not category bundles.

- [ ] **Step 4: Run formatting verification**

Run:

```bash
just treefmt-check
```

Expected: PASS, or the exact formatter/Nix-daemon baseline limitation from Task 1.

- [ ] **Step 5: Run focused and full flake checks**

Run each command separately:

```bash
nix build 'path:.#checks.x86_64-linux.vcs-identity' --print-build-logs
nix flake check path:. --print-build-logs
just check
```

Expected: PASS in a normal checkout. In the managed checkout, only the exact Task 1 environment failures are acceptable.

- [ ] **Step 6: Evaluate representative cross-platform outputs**

Run each command separately:

```bash
nix eval 'path:.#nixosConfigurations.acerus.config.system.build.toplevel.drvPath' --raw
nix eval 'path:.#nixosConfigurations.esquire.config.system.build.toplevel.drvPath' --raw
nix eval 'path:.#nixosConfigurations.vps.config.system.build.toplevel.drvPath' --raw
nix eval 'path:.#darwinConfigurations.mbp.system' --raw
nix eval 'path:.#homeConfigurations.seraphyne.activationPackage.drvPath' --raw
```

Expected: all supported outputs evaluate, or each failure exactly matches its Task 1 baseline limitation. The known standalone Home Manager/OpenCommit limitation described in the NDD-91 design is acceptable only if unchanged.

- [ ] **Step 7: Review the complete diff for behavioral changes**

Run:

```bash
jj diff --stat
jj diff
```

Expected: module bodies contain the same package names, option values, secret paths, source paths, and scripts. Differences are limited to file relocation, outer argument unions, section comments, and formatter-required indentation.

- [ ] **Step 8: Create the final local checkpoint if pending changes remain**

Run:

```bash
jj status
jj commit -m "refactor: organize modules by category"
```

Expected: any remaining verified changes are committed locally. If the known object-store restriction blocks the commit, leave the verified working copy intact, report that no commit was created, and do not contact upstream or use Git.

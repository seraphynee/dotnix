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


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


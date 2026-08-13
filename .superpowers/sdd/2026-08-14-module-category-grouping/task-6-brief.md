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

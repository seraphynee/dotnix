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


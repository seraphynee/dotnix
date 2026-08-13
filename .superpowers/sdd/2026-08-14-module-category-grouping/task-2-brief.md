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


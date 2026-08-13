# NDD-91 Declarative VCS Identity Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace username-based Git/Jujutsu profile selection with typed per-user Home Manager options that provide one author identity to both tools.

**Architecture:** User aspects own concrete `dotnix.vcs` profiles. A public `<shell/vcs>` Den aspect imports three focused Home Manager modules from `lib/shell/vcs`: the typed profile contract, Git configuration, and Jujutsu configuration. The helpers live outside `modules/` and `nix/` because the repository's `import-tree` expression automatically treats `.nix` files beneath those roots as top-level flake modules.

**Tech Stack:** Nix Flakes, vic/den aspects, Home Manager modules, flake-parts checks, sops-nix, `just`.

## Global Constraints

- Preserve the author names `chianyungcode` and `seraphynee` and their current email addresses.
- Both Git and Jujutsu must consume `config.dotnix.vcs.identity`; neither may derive identity from runtime state or from the other tool's output.
- Shared VCS code must not branch on `user.userName`, repository user constants, or hard-coded user-specific values.
- Keep this work independent of the reusable user builder or central registry proposed by NDD-39.
- Keep Git and Jujutsu enablement independent: Seraphyne receives both, Chianyung receives Git only, and Micha and Admin receive neither.
- Optional PAT and signing paths must be resolved through existing sops-nix configuration only; never add plaintext secret material.
- Preserve NixOS, nix-darwin, and standalone Home Manager evaluation.
- Use only modern flake commands and the repository's `just` checks.
- Do not broaden the refactor to unrelated shell modules.

---

## File Map

- Create `modules/shell/vcs.nix`: public Den aspect; imports the three reusable Home Manager modules.
- Create `lib/shell/vcs/profile.nix`: typed `dotnix.vcs` option contract and identity assertions.
- Create `lib/shell/vcs/git.nix`: Git settings, packages, secrets, and shell integration gated by `dotnix.vcs.git.enable`.
- Create `lib/shell/vcs/jujutsu.nix`: Jujutsu/JJUI settings, packages, secrets, and shell integration gated by `dotnix.vcs.jujutsu.enable`.
- Create `nix/vcs-identity-tests.nix`: evaluation-only flake check for option validation, identity sharing, tool gating, and profile isolation.
- Modify `modules/users/seraphyne.nix`: declare Seraphyne's profile and include `<shell/vcs>`.
- Modify `modules/users/chianyung.nix`: declare Chianyung's Git-only profile and include `<shell/vcs>`.
- Modify `modules/users/micha.nix`: remove the inherited Git include; do not invent a profile.
- Delete `modules/shell/git.nix`: replaced by the Git Home Manager helper.
- Delete `modules/shell/jujutsu.nix`: replaced by the Jujutsu Home Manager helper.

---

### Task 1: Add the typed VCS profile contract

**Files:**

- Create: `lib/shell/vcs/profile.nix`
- Create: `nix/vcs-identity-tests.nix`

**Interfaces:**

- Consumes: Home Manager's `config`, `lib`, `home.username`, `home.homeDirectory`, and `home.stateVersion` options.
- Produces: `config.dotnix.vcs` with `identity`, `github`, `signing`, `git`, and `jujutsu` sub-options; `config.assertions` rejects incomplete enabled profiles.

- [ ] **Step 1: Write the failing profile evaluation check**

Create `nix/vcs-identity-tests.nix` with the profile-only check below. It intentionally imports a file that does not exist yet.

```nix
{
  inputs,
  lib,
  ...
}:
{
  perSystem =
    {
      pkgs,
      ...
    }:
    let
      mkProfileHome = profile:
        inputs.home-manager.lib.homeManagerConfiguration {
          inherit pkgs;
          modules = [
            ../lib/shell/vcs/profile.nix
            {
              home = {
                username = "vcs-test";
                homeDirectory = if pkgs.stdenv.isDarwin then "/Users/vcs-test" else "/home/vcs-test";
                stateVersion = "26.11";
              };
              dotnix.vcs = profile;
            }
          ];
        };

      assertionsPass = home: lib.all (entry: entry.assertion) home.config.assertions;

      valid = mkProfileHome {
        identity = {
          name = "alpha";
          email = "alpha@example.test";
        };
        git.enable = true;
      };

      missingName = mkProfileHome {
        identity.email = "missing-name@example.test";
        git.enable = true;
      };

      missingEmail = mkProfileHome {
        identity.name = "missing-email";
        jujutsu.enable = true;
      };
    in
    {
      checks.vcs-identity =
        assert valid.config.dotnix.vcs.identity.name == "alpha";
        assert valid.config.dotnix.vcs.identity.email == "alpha@example.test";
        assert assertionsPass valid;
        assert !assertionsPass missingName;
        assert !assertionsPass missingEmail;
        pkgs.runCommand "vcs-identity-evaluation" { } ''
          touch "$out"
        '';
    };
}
```

Stage the new test file so flake source filtering includes it during the red run:

```bash
git add nix/vcs-identity-tests.nix
```

- [ ] **Step 2: Run the check and confirm the missing module failure**

Run:

```bash
nix build .#checks.x86_64-linux.vcs-identity --print-build-logs
```

Expected: FAIL because `lib/shell/vcs/profile.nix` does not exist.

- [ ] **Step 3: Implement the typed profile module**

Create `lib/shell/vcs/profile.nix`:

```nix
{
  config,
  lib,
  ...
}:
let
  inherit (lib) mkOption types;
  cfg = config.dotnix.vcs;
  vcsEnabled = cfg.git.enable || cfg.jujutsu.enable;
  nonEmpty = value: value != null && value != "";
in
{
  options.dotnix.vcs = {
    identity = {
      name = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Commit author name shared by Git and Jujutsu.";
      };
      email = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Commit author email shared by Git and Jujutsu.";
      };
    };

    github = {
      username = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "GitHub account name, independent from commit author identity.";
      };
      patSecret = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "sops-nix secret name containing the GitHub personal access token.";
      };
    };

    signing.keySecret = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "sops-nix secret name containing the shared SSH signing public key.";
    };

    git.enable = mkOption {
      type = types.bool;
      default = false;
      description = "Enable the shared Git configuration.";
    };

    jujutsu = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = "Enable the shared Jujutsu configuration.";
      };
      bookmarkPrefix = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Explicit prefix for generated Jujutsu push bookmarks.";
      };
      workstation = mkOption {
        type = types.bool;
        default = false;
        description = "Enable workstation-only Jujutsu diff tooling.";
      };
    };
  };

  config.assertions = lib.optionals vcsEnabled [
    {
      assertion = nonEmpty cfg.identity.name;
      message = "dotnix.vcs.identity.name must be non-empty when Git or Jujutsu is enabled";
    }
    {
      assertion = nonEmpty cfg.identity.email;
      message = "dotnix.vcs.identity.email must be non-empty when Git or Jujutsu is enabled";
    }
  ];
}
```

Stage the new module so the flake sees it during the green run:

```bash
git add lib/shell/vcs/profile.nix
```

- [ ] **Step 4: Run the focused check**

Run:

```bash
nix build .#checks.x86_64-linux.vcs-identity --print-build-logs
```

Expected: PASS and create the `vcs-identity-evaluation` derivation.

- [ ] **Step 5: Commit the profile contract and check**

```bash
git add lib/shell/vcs/profile.nix nix/vcs-identity-tests.nix
git commit -m "feat(vcs): add typed per-user identity profile"
```

---

### Task 2: Make Git consume the shared profile

**Files:**

- Create: `lib/shell/vcs/git.nix`
- Modify: `nix/vcs-identity-tests.nix`
- Reference during migration: `modules/shell/git.nix`

**Interfaces:**

- Consumes: `config.dotnix.vcs.identity`, `config.dotnix.vcs.github`, `config.dotnix.vcs.signing.keySecret`, and `config.dotnix.vcs.git.enable` from Task 1.
- Produces: gated Home Manager Git configuration with the existing packages, aliases, signing behavior, credentials, ignore file, Bash token export, and Fish abbreviations.

- [ ] **Step 1: Extend the check with Git identity and isolation assertions**

In `nix/vcs-identity-tests.nix`, rename `mkProfileHome` to `mkVcsHome`, add `../lib/shell/vcs/git.nix` immediately after the profile import, and replace the single valid fixture with these two profiles:

```nix
      seraphyne = mkVcsHome {
        identity = {
          name = "seraphynee";
          email = "seraphyne31@gmail.com";
        };
        github.username = "seraphynee";
        git.enable = true;
      };

      chianyung = mkVcsHome {
        identity = {
          name = "chianyungcode";
          email = "cnytechcode@gmail.com";
        };
        github.username = "chianyungcode";
        git.enable = true;
      };
```

Replace the `valid` assertions in `checks.vcs-identity` with:

```nix
        assert assertionsPass seraphyne;
        assert assertionsPass chianyung;
        assert seraphyne.config.programs.git.settings.user == {
          name = "seraphynee";
          email = "seraphyne31@gmail.com";
        };
        assert chianyung.config.programs.git.settings.user == {
          name = "chianyungcode";
          email = "cnytechcode@gmail.com";
        };
        assert seraphyne.config.programs.git.settings.user != chianyung.config.programs.git.settings.user;
        assert seraphyne.config.programs.git.settings.credential."https://github.com".username == "seraphynee";
        assert seraphyne.config.programs.git.settings.alias.co == "checkout";
```

Keep both negative fixtures and their assertions.

- [ ] **Step 2: Run the check and confirm the missing Git module failure**

Run:

```bash
nix build .#checks.x86_64-linux.vcs-identity --print-build-logs
```

Expected: FAIL because `lib/shell/vcs/git.nix` does not exist.

- [ ] **Step 3: Refactor the current Git configuration into a gated Home Manager module**

Create `lib/shell/vcs/git.nix` by mechanically extracting the two configuration bodies from `modules/shell/git.nix`: the attrset returned by `mkGitProfile` and the package/Fish attrset merged beside it in `den.aspects.shell._.git.homeManager`. Retain the existing `mkConventionalAlias` definition as the final binding in the new `let`. Replace the old outer module, profile factory, username dispatch, and Den aspect wrappers with this prefix:

```nix
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.dotnix.vcs;
  inherit (pkgs.stdenv.hostPlatform) isDarwin;

  secretPath = secret:
    if secret == null then
      null
    else
      lib.attrByPath [
        "sops"
        "secrets"
        secret
        "path"
      ] null config;

  githubPATPath = secretPath cfg.github.patSecret;
  signingKeyPath = secretPath cfg.signing.keySecret;
```

After `mkConventionalAlias`, set `config = lib.mkIf cfg.git.enable` to the merge of those two extracted attrsets. This preserves every existing setting while changing only the data source and enable gate. Update the relocated ignore-file reference for its new directory depth:

```nix
xdg.configFile."git/ignore".source = ../../../dots/config/git/ignore;
```

Apply these exact substitutions while moving the existing configuration body:

```nix
programs.git.settings.user = {
  name = cfg.identity.name;
  email = cfg.identity.email;
};
```

Build the GitHub credential subsection conditionally so a missing optional username does not emit a null setting:

```nix
credential =
  {
    helper = lib.optionals isDarwin [ "osxkeychain" ] ++ [
      "/usr/local/share/gcm-core/git-credential-manager"
    ];
    "https://dev.azure.com".useHttpPath = true;
  }
  // lib.optionalAttrs (cfg.github.username != null) {
    "https://github.com".username = cfg.github.username;
  }
  // lib.optionalAttrs (!isDarwin) {
    credentialStore = "cache";
    guiPrompt = false;
  };
```

Keep signing conditional on `signingKeyPath != null`, keep PAT environment/Bash configuration conditional on `githubPATPath != null`, and remove all references to `constants`, `user.userName`, `gitProfile`, `mkGitProfile`, and `den.aspects.shell._.git` from the new helper.

Stage the new helper before the green run:

```bash
git add lib/shell/vcs/git.nix
```

- [ ] **Step 4: Run the focused check**

Run:

```bash
nix build .#checks.x86_64-linux.vcs-identity --print-build-logs
```

Expected: PASS; the check proves distinct profiles remain isolated and the existing `co` alias survives the refactor.

- [ ] **Step 5: Commit the Git consumer**

```bash
git add lib/shell/vcs/git.nix nix/vcs-identity-tests.nix
git commit -m "refactor(vcs): drive git from the shared identity profile"
```

---

### Task 3: Make Jujutsu consume the same profile

**Files:**

- Create: `lib/shell/vcs/jujutsu.nix`
- Modify: `nix/vcs-identity-tests.nix`
- Reference during migration: `modules/shell/jujutsu.nix`

**Interfaces:**

- Consumes: the identity and signing options from Task 1, plus `github.username`, `jujutsu.enable`, `jujutsu.bookmarkPrefix`, and `jujutsu.workstation`.
- Produces: gated Jujutsu/JJUI settings, packages, signing behavior, merge tools, templates, aliases, and Fish abbreviations.

- [ ] **Step 1: Extend the check with Jujutsu sharing and gating assertions**

Add `../lib/shell/vcs/jujutsu.nix` after the Git helper import. Set `seraphyne.jujutsu.enable = true` and `seraphyne.jujutsu.workstation = true`; leave Chianyung's Jujutsu defaults unchanged. Add these assertions to `checks.vcs-identity`:

```nix
        assert seraphyne.config.programs.jujutsu.settings.user == seraphyne.config.programs.git.settings.user;
        assert seraphyne.config.programs.jujutsu.settings.templates.git_push_bookmark == ''"seraphynee/push-" ++ change_id.short()'';
        assert seraphyne.config.programs.jujutsu.settings.ui."diff-formatter" == [
          "difft"
          "--color=always"
          "$left"
          "$right"
        ];
        assert !chianyung.config.programs.jujutsu.enable;
```

Add one explicit-prefix fixture:

```nix
      explicitPrefix = mkVcsHome {
        identity = {
          name = "author-name";
          email = "author@example.test";
        };
        github.username = "forge-name";
        jujutsu = {
          enable = true;
          bookmarkPrefix = "custom-prefix";
        };
      };
```

And assert:

```nix
        assert explicitPrefix.config.programs.jujutsu.settings.templates.git_push_bookmark == ''"custom-prefix/push-" ++ change_id.short()'';
```

- [ ] **Step 2: Run the check and confirm the missing Jujutsu module failure**

Run:

```bash
nix build .#checks.x86_64-linux.vcs-identity --print-build-logs
```

Expected: FAIL because `lib/shell/vcs/jujutsu.nix` does not exist.

- [ ] **Step 3: Refactor the current Jujutsu configuration into a gated Home Manager module**

Create `lib/shell/vcs/jujutsu.nix` by mechanically extracting the attrset returned by `mkJujutsuProfile` and the base package/JJUI/Fish attrset under `den.aspects.shell._.jujutsu.homeManager`. Preserve every existing UI, merge-tool, template-alias, command-alias, snapshot, JJUI, package, and Fish abbreviation setting. Replace the old outer module, profile factory, Den aspect, and named providers with this prefix:

```nix
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.dotnix.vcs;
  signingKeyPath =
    if cfg.signing.keySecret == null then
      null
    else
      lib.attrByPath [
        "sops"
        "secrets"
        cfg.signing.keySecret
        "path"
      ] null config;
  bookmarkPrefix =
    if cfg.jujutsu.bookmarkPrefix != null then
      cfg.jujutsu.bookmarkPrefix
    else if cfg.github.username != null then
      cfg.github.username
    else
      cfg.identity.name;
```

Set `config = lib.mkIf cfg.jujutsu.enable` to `lib.mkMerge` of the two extracted attrsets after this `let` block. This retains the existing behavior while applying one enable gate around the complete Jujutsu feature.

Apply these exact substitutions:

```nix
programs.jujutsu.settings.user = {
  name = cfg.identity.name;
  email = cfg.identity.email;
};

programs.jujutsu.settings.templates.git_push_bookmark =
  ''"${bookmarkPrefix}/push-" ++ change_id.short()'';
```

Replace every use of the old `workstation` function argument with `cfg.jujutsu.workstation`. Keep signing conditional on the resolved shared `signingKeyPath`. Remove `mkJujutsuProfile`, the `provides.chianyungcode` and `provides.seraphyne` profiles, and all `gitUser`, `gitEmail`, and user-named sub-aspect references from the new helper.

Stage the new helper before the green run:

```bash
git add lib/shell/vcs/jujutsu.nix
```

- [ ] **Step 4: Run the focused check**

Run:

```bash
nix build .#checks.x86_64-linux.vcs-identity --print-build-logs
```

Expected: PASS; Git and Jujutsu author settings are identical for Seraphyne, Chianyung's Jujutsu remains disabled, and explicit bookmark-prefix override wins.

- [ ] **Step 5: Commit the Jujutsu consumer**

```bash
git add lib/shell/vcs/jujutsu.nix nix/vcs-identity-tests.nix
git commit -m "refactor(vcs): share identity with jujutsu"
```

---

### Task 4: Publish the VCS aspect and migrate user ownership

**Files:**

- Create: `modules/shell/vcs.nix`
- Modify: `modules/users/seraphyne.nix`
- Modify: `modules/users/chianyung.nix`
- Modify: `modules/users/micha.nix`
- Delete: `modules/shell/git.nix`
- Delete: `modules/shell/jujutsu.nix`

**Interfaces:**

- Consumes: all three reusable Home Manager modules completed in Tasks 1-3.
- Produces: public `<shell/vcs>` aspect and concrete per-user profiles for every user who enables VCS tooling.

- [ ] **Step 1: Record the existing full standalone-home blocker**

Run before changing includes:

```bash
nix eval --json .#homeConfigurations.seraphyne.config.programs.git.settings.user
```

Expected: FAIL at `modules/shell/opencommit.nix` because that unrelated module directly requires `config.sops.placeholder` in an unbound standalone home. Record this baseline and do not expand NDD-91 to fix OpenCommit. The isolated `mkVcsHome` flake check is the authoritative standalone Home Manager verification for this scope.

- [ ] **Step 2: Create the public VCS aspect**

Create `modules/shell/vcs.nix`:

```nix
{
  den.aspects.shell._.vcs.homeManager.imports = [
    ../../lib/shell/vcs/profile.nix
    ../../lib/shell/vcs/git.nix
    ../../lib/shell/vcs/jujutsu.nix
  ];
}
```

Stage the new public module immediately so subsequent flake evaluations include it:

```bash
git add modules/shell/vcs.nix
```

- [ ] **Step 3: Move concrete profile ownership into user aspects**

In `modules/users/seraphyne.nix`, replace `<shell/git>` and `<shell/jujutsu/seraphyne>` with one `<shell/vcs>` include, then add this sibling of `nixos` inside `den.aspects.${constants.user_two}`:

```nix
    homeManager.dotnix.vcs = {
      identity = {
        name = "seraphynee";
        email = "seraphyne31@gmail.com";
      };
      github = {
        username = "seraphynee";
        patSecret = "keys/pat/ghspy-pat";
      };
      signing.keySecret = "keys/ssh/github/signing/ghspy-pub";
      git.enable = true;
      jujutsu = {
        enable = true;
        workstation = true;
      };
    };
```

In `modules/users/chianyung.nix`, replace `<shell/git>` with `<shell/vcs>`, then add this sibling of `darwin` and `nixos` inside `den.aspects.${constants.user_one}`:

```nix
    homeManager.dotnix.vcs = {
      identity = {
        name = "chianyungcode";
        email = "cnytechcode@gmail.com";
      };
      github.username = "chianyungcode";
      signing.keySecret = "keys/ssh/github/signing/ghcny-pub";
      git.enable = true;
    };
```

In `modules/users/micha.nix`, remove `<shell/git>` and do not add `<shell/vcs>` or a `dotnix.vcs` profile.

- [ ] **Step 4: Remove the superseded tool aspects**

Delete only these two files with `apply_patch` after all user includes point to `<shell/vcs>`:

```diff
*** Delete File: modules/shell/git.nix
*** Delete File: modules/shell/jujutsu.nix
```

Do not delete any files under `dots/config/git` or shell configuration directories; the new helpers still reference them.

- [ ] **Step 5: Evaluate the real platform configurations**

Run:

```bash
nix eval --json .#nixosConfigurations.acerus.config.home-manager.users.seraphyne.programs.git.settings.user
nix eval --json .#nixosConfigurations.acerus.config.home-manager.users.seraphyne.programs.jujutsu.settings.user
nix eval --json .#darwinConfigurations.mbp.config.home-manager.users.chianyung.programs.git.settings.user
nix eval --json .#darwinConfigurations.mbp.config.home-manager.users.chianyung.programs.jujutsu.enable
```

Expected outputs, in order:

```text
{"email":"seraphyne31@gmail.com","name":"seraphynee"}
{"email":"seraphyne31@gmail.com","name":"seraphynee"}
{"email":"cnytechcode@gmail.com","name":"chianyungcode"}
false
```

The `nix/vcs-identity-tests.nix` check separately instantiates the VCS helpers with `home-manager.lib.homeManagerConfiguration`; that is the standalone evaluation required by this scope until the unrelated OpenCommit blocker is fixed.

- [ ] **Step 6: Verify shared code contains no user dispatch or concrete identity**

Run:

```bash
rg -n 'user\.userName|constants\.user_|seraphynee|seraphyne31@gmail\.com|chianyungcode|cnytechcode@gmail\.com' modules/shell/vcs.nix lib/shell/vcs
```

Expected: no matches.

Confirm concrete values are confined to the intended user modules and test fixtures:

```bash
rg -n 'seraphynee|seraphyne31@gmail\.com|chianyungcode|cnytechcode@gmail\.com' modules/users nix/vcs-identity-tests.nix
```

Expected: matches only in `modules/users/seraphyne.nix`, `modules/users/chianyung.nix`, and the named test file.

- [ ] **Step 7: Run all focused and repository checks**

Run:

```bash
nix build .#checks.x86_64-linux.vcs-identity --print-build-logs
just treefmt-check
just check
```

Expected: all commands exit successfully with no failed flake checks or formatting changes.

- [ ] **Step 8: Commit the public aspect and user migration**

```bash
git add modules/shell/vcs.nix lib/shell/vcs modules/users/seraphyne.nix modules/users/chianyung.nix modules/users/micha.nix nix/vcs-identity-tests.nix
git add -u modules/shell/git.nix modules/shell/jujutsu.nix
git commit -m "refactor(vcs): derive identity from user configuration"
```

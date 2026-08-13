# NDD-91 Scope 2: Declarative VCS Identity Design

## Context

NDD-91 requires Git and Jujutsu to derive author identity from the selected declarative user configuration. The current implementation does not provide a single trustworthy source:

- `modules/shell/git.nix` chooses a profile by comparing `user.userName` with repository constants.
- `modules/shell/jujutsu.nix` exposes user-named sub-aspects such as `<shell/jujutsu/seraphyne>`.
- Author name and email are duplicated between the two modules.
- The Git profile branch currently assigns Seraphyne's identity to Micha.
- The value named `gitUser` also serves as a GitHub username and Jujutsu bookmark prefix, although those are separate concepts.

The pinned Den version supplies a `user` entity to host-bound configurations, but an unbound standalone home has no corresponding Den user entity. Therefore, consuming `user` directly inside the shared VCS aspect would not satisfy the standalone Home Manager requirement without broadening this issue into the user-registry work tracked by NDD-39.

## Goals

- Give Git and Jujutsu one declarative source for author name and email.
- Keep identity values owned by the selected user aspect.
- Preserve the current author names `chianyungcode` and `seraphynee`.
- Resolve each Home Manager user's profile independently on multi-user hosts.
- Support NixOS, nix-darwin, and standalone Home Manager evaluation.
- Remove username dispatch and user-specific values from shared VCS configuration.
- Fail evaluation instead of silently borrowing another user's identity.

## Non-goals

- Implement the reusable user builder or central registry proposed by NDD-39.
- Change existing author names or email addresses.
- Infer identity from the runtime shell, environment variables, the host account database, or Git configuration outside Nix.
- Invent an author identity for Micha when no correct email is currently declared.
- Perform shell-module grouping beyond the VCS boundary required by NDD-91.

## Decision

Define typed Home Manager options under `dotnix.vcs`. Each user aspect declares its own profile through those options, and the shared VCS aspect consumes only the evaluated option values.

This keeps the design independent of Den's host-bound `user` argument. Den already evaluates the selected user aspect separately for each Home Manager user, including the standalone `den.homes` output, so the profile follows the user selection without runtime detection or a new global registry.

## Option Interface

The shared VCS Home Manager module defines this conceptual interface:

```nix
dotnix.vcs = {
  identity = {
    name = null;
    email = null;
  };

  github = {
    username = null;
    patSecret = null;
  };

  signing.keySecret = null;

  git.enable = false;

  jujutsu = {
    enable = false;
    bookmarkPrefix = null;
    workstation = false;
  };
};
```

The implementation uses typed options with the following semantics:

- `identity.name`: nullable string; required and non-empty when either VCS tool is enabled.
- `identity.email`: nullable string; required and non-empty when either VCS tool is enabled.
- `github.username`: optional forge account name, separate from commit-author identity.
- `github.patSecret`: optional SOPS secret name for the GitHub personal access token.
- `signing.keySecret`: optional SOPS secret name shared by Git and Jujutsu signing configuration.
- `git.enable`: enables the Git configuration and Git-specific packages and shell integration.
- `jujutsu.enable`: enables Jujutsu configuration, packages, and shell integration.
- `jujutsu.bookmarkPrefix`: optional explicit prefix for generated push bookmarks. When unset, its effective value is `github.username` when available, otherwise `identity.name`.
- `jujutsu.workstation`: enables workstation-only diff tooling without coupling it to identity.

Tool enablement is explicit so consolidating the files under a category-oriented VCS aspect does not make every user receive both tools.

## Ownership and Components

### User aspects

`modules/users/<user>.nix` owns concrete profile data. A user that wants VCS tooling includes `<shell/vcs>` and sets `homeManager.dotnix.vcs` in the same user aspect.

For example, Seraphyne's declaration is conceptually:

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

### Shared VCS aspect

The shared `<shell/vcs>` aspect owns the option declarations and common implementation. It has no knowledge of repository user constants, operating-system account names, or user-specific email addresses.

Its responsibilities are:

1. Validate the selected profile.
2. Resolve optional SOPS secret paths from Home Manager `config`.
3. Feed `identity.name` and `identity.email` to both `programs.git.settings.user` and `programs.jujutsu.settings.user`.
4. Configure GitHub credentials only from `github` fields.
5. Configure signing for both tools from the same resolved `signing.keySecret` path.
6. Configure Jujutsu's bookmark prefix from its own effective prefix value.
7. Gate tool-specific packages, shell abbreviations, and settings behind the corresponding enable option.

The category-oriented file refactor in NDD-91 scope 1 can place these components in `modules/shell/vcs.nix`; the option boundary defined here remains the same if implementation details are split into focused helpers.

## Data Flow

```text
modules/users/<user>.nix
        |
        `-- homeManager.dotnix.vcs
                  |
                  |-- identity ----> Git author name/email
                  |              `-> Jujutsu author name/email
                  |-- github ------> GitHub credentials
                  |              `-> default Jujutsu bookmark prefix
                  |-- signing -----> shared optional signing-key path
                  `-- tool flags ---> Git/Jujutsu packages and behavior
```

For a host with multiple Home Manager users, Den evaluates each user's selected aspect into that user's separate Home Manager module instance. Consequently, `config.dotnix.vcs` cannot be shared accidentally between users. An unbound standalone home receives the same values from its selected user aspect and does not require a Den `user` argument.

## Validation and Error Handling

- Enabling Git or Jujutsu without both a non-empty author name and email produces a clear Nix assertion failure naming the missing `dotnix.vcs.identity` option.
- A disabled tool emits no program settings, packages, or shell integration for that tool.
- Optional PAT and signing integrations activate only when their configured SOPS path exists in the evaluated Home Manager configuration.
- A missing optional secret path does not prevent standalone Home Manager evaluation; the related integration remains disabled, matching the repository's existing cross-platform behavior.
- The shared module contains no fallback profile and never selects identity by `user.userName`.
- Jujutsu and Git receive the same author values directly from `config.dotnix.vcs.identity`; neither derives identity from the other tool's generated configuration.

## Migration

The migration preserves existing intended behavior as follows:

| User | Git | Jujutsu | Author name | Author email | Migration result |
| --- | --- | --- | --- | --- | --- |
| Seraphyne | enabled | enabled | `seraphynee` | `seraphyne31@gmail.com` | Move values into the Seraphyne user aspect. |
| Chianyung | enabled | disabled | `chianyungcode` | `cnytechcode@gmail.com` | Move values into the Chianyung user aspect; do not enable Jujutsu. |
| Micha | disabled | disabled | none | none | Remove inherited Seraphyne Git profile; leave VCS disabled until Micha declares a complete profile. |
| Admin | disabled | disabled | none | none | No change. |

The user modules also own their existing GitHub usernames, PAT secret names, signing secret names, and workstation flags. Those values are removed from the shared implementation at the same time as author identity.

## Testing Strategy

### Positive evaluations

- Evaluate `nixosConfigurations.acerus.config.home-manager.users.seraphyne` and confirm both Git and Jujutsu contain the preserved Seraphyne author identity.
- Evaluate `homeConfigurations.seraphyne` and confirm its Git and Jujutsu author values match the NixOS-hosted result.
- Evaluate `darwinConfigurations.mbp.config.home-manager.users.chianyung` and confirm Git contains Chianyung's profile while Jujutsu remains disabled.
- Compare the generated Git and Jujutsu `user` settings for Seraphyne and require exact equality.
- Evaluate two distinct user-profile fixtures in the same test and assert that each generated configuration retains only its own identity. This directly covers the multi-user isolation acceptance criterion.

### Negative evaluations

- Evaluate a fixture with `git.enable = true` and no identity; it must fail with the identity assertion.
- Evaluate a fixture with `jujutsu.enable = true` and only one identity field; it must fail with the identity assertion.
- Confirm Micha has no generated VCS program configuration after migration.

### Repository checks

- Run targeted `nix eval` commands for the configurations above.
- Run `just treefmt-check`.
- Run `just check`.
- Search the shared VCS implementation for the preserved names, email addresses, user constants, and username comparisons; all user-specific occurrences must be confined to user modules or test fixtures.

## Acceptance Mapping

- **One identity source:** both tools consume `config.dotnix.vcs.identity`.
- **No shared hard-coding:** concrete profiles live in user aspects.
- **Explicit input:** typed Home Manager options form the VCS module interface.
- **Multi-user correctness:** each user's separate Home Manager evaluation carries its own profile, with a two-profile isolation test.
- **Cross-platform support:** the design avoids runtime detection and the host-only Den `user` entity.
- **Reproducible verification:** targeted evaluations and the repository's flake and formatting checks cover the generated configurations.

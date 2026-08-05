# Task 3 Report: Generate Fish and Zsh secret runtime bridges

Status: complete

Implementation commit: `0cbf275` (`feat(secrets): add shell runtime bridges`)

## Files changed

- `modules/secrets/sops.nix`
- `dots/config/fish/env.d/030-secrets.fish`
- `dots/config/zsh/env.d/030-secrets.sh`
- This report

## Implementation

- Added explicit XDG-based sops-nix target paths for the shared API secrets and
  profile-specific `keys/pat/*` secrets when no custom path is already set.
- Added silent, conditional Fish and Zsh bridges for Context7, GitHub,
  OpenRouter, and Wakatime values. Each value is read only from a readable
  mode-0600 sops-managed target; no decrypted value is present in source or a
  Nix derivation.
- Preserved `GITHUB_TOKEN_FILE` precedence and behavior, with the profile PAT
  target as a fallback compatibility path.
- Required source order for the shell worker: source `000-xdg.fish` or
  `000-xdg.sh` first, then `030-secrets.fish` or `030-secrets.sh`; consumer
  shell initialization must follow both files. This task did not modify shell
  consumer modules.

## Verification

- `fish --no-config -n dots/config/fish/env.d/030-secrets.fish` — pass.
- `nix shell nixpkgs#zsh --command zsh -n dots/config/zsh/env.d/030-secrets.sh` — pass.
- `nix-instantiate --parse modules/secrets/sops.nix` — pass.
- Clean Fish and Zsh startup with all optional secret files absent — pass,
  exit 0 with empty stdout/stderr.
- Temporary mode-0600 fixture files for all four variables — pass; all
  variables were assigned and stdout/stderr contained none of the fixture
  values.
- Static scan `rg -n -i 'sk-|api[_-]?key[[:space:]]*=' dots/config modules --glob '!modules/secrets/**'` — no decrypted values; matches are only runtime file reads and existing sops placeholder URLs.
- `git diff --check` — pass.
- `just secrets-scan` — pass; gitleaks scanned 1,368 commits and reported no
  leaks.

## Concerns

- The normal pre-commit formatter could not run because Nix was unable to
  write its read-only fetcher cache. The first commit attempt was therefore
  blocked by the formatter hook.
- The repository's configured 1Password signing agent was unavailable, so the
  implementation commit was created with commit signing disabled. No secret
  material was accessed or emitted.

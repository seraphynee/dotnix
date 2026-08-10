# Task 1 Report: Shell Runtime Secret Environment

## Status

Implemented and committed. The runtime secret mapping is defined in `modules/shell/env.nix`, filtered to configured SOPS declarations, and rendered into Fish and Zsh startup initialization. The duplicate Fish GitHub token loader was removed from `modules/shell/git.nix`; `GITHUB_TOKEN_FILE` and the existing Bash loader remain.

## Commit IDs

- Implementation: `c571cfe8` — `feat(env): centralize shell runtime secrets`
- The report is a separate documentation-only change after the implementation commit.

## Changed paths

- `modules/shell/env.nix`
- `modules/shell/git.nix`

No changes were made to `modules/secrets/sops.nix` or the static `030-secrets` files.

## Tests

- `nixfmt modules/shell/env.nix modules/shell/git.nix` — exit 0.
- `nixfmt --check modules/shell/env.nix modules/shell/git.nix` — exit 0.
- `nix-instantiate --parse modules/shell/env.nix >/dev/null` — exit 0.
- `nix-instantiate --parse modules/shell/git.nix >/dev/null` — exit 0.
- Required structural Nix evaluation and assertions — exit 0; each generated block appeared once, both shells contained the four required variable names, Fish Git ownership was absent from `git.nix`, and Bash ownership remained.
- Required 0600 Fish/Zsh sentinel fixture test — exit 0; both loaders populated variables and produced empty stdout/stderr.
- Required missing-file test — exit 1 because its `env -i ... zsh` subcommand could not resolve the Zsh binary after the Nix shell PATH was overwritten.
- Equivalent missing-file test preserving the Nix-provided Zsh PATH — exit 0; both shells left variables unset with empty stdout/stderr.

## Self-review

- Only paths within the requested implementation scope were changed for the implementation commit.
- Nix contains secret names and runtime paths only; no decrypted contents are evaluated or read during evaluation.
- The Fish and Zsh loaders use readability checks, avoid diagnostics, and read files only at shell startup.
- `000-xdg` rendering and loading contracts are unchanged.
- The runtime block is added with `lib.mkBefore`, and variable traversal is deterministic through Nix attribute ordering.
- The Git profile-specific `GITHUB_TOKEN_FILE` mapping and existing Bash behavior are preserved.

## Concerns

The exact missing-file command in the brief is not portable in this environment: `nix shell nixpkgs#zsh --command env -i ... PATH="$PATH" zsh` resets the PATH to the outer shell value, so `zsh` is not found. The equivalent test with the Nix-provided Zsh PATH passed. No implementation concern remains.

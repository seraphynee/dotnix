# Task 1 Report: Define Home Manager XDG environment values

Commit: 122f58d9eb3b3095e05d444d7c23bd01ae6687b2

## Files changed

- `modules/shell/env.nix`
- `dots/config/fish/env.d/000-xdg.fish`
- `dots/config/zsh/env.d/000-xdg.sh`
- This report

## Implementation decisions

- Added a Home Manager environment aspect that renders Fish and Zsh files from `config.xdg.dataHome`, `config.xdg.configHome`, `config.xdg.stateHome`, `config.xdg.cacheHome`, and `config.xdg.userDirs`.
- Kept `XDG_DATA_DIRS` runtime-derived: split the existing colon-separated value, remove empty and duplicate entries, and add the configured data home only when absent.
- Added configured XDG user-directory values as fallbacks and guarded `xdg-user-dir` overrides behind command-availability checks.
- Did not add or modify Fish/Zsh consumer module wiring or introduce a Chez Moi path.
- No decrypted secret values were used or written.

## Commands run and results

- `fish --no-config -n dots/config/fish/env.d/000-xdg.fish` — exit 0; empty output.
- `nix shell nixpkgs#zsh --command zsh -n dots/config/zsh/env.d/000-xdg.sh` — exit 0; empty output.
- `nix-instantiate --parse modules/shell/env.nix` — exit 0; parse succeeded.
- Rendered shell-file checks with empty `XDG_DATA_DIRS` and with `/usr/share:/tmp/xdg-data:/usr/share` — exit 0; Fish and Zsh both produced `/tmp/xdg-data` exactly once.
- `just secrets-scan` — exit 0; gitleaks scanned 1,362 commits and reported `no leaks found`.
- `git diff --cached --check` — exit 0; no whitespace errors.
- `just check` — exit 1 in the repository treefmt sub-check only. All flake configuration evaluation stages completed; the unrelated pre-existing `modules/shell/llm-agents.nix` formatting mismatch caused treefmt to fail.
- `just treefmt-check` — exit 1 for the same unrelated `modules/shell/llm-agents.nix` formatting mismatch. The unrelated file is not included in this task’s changes.

## Concerns

- The environment lacks a system `zsh`; the required Zsh checks were run through the pinned Nix package instead.
- Repository-wide formatting checks remain red because treefmt wants to reformat unrelated existing changes in `modules/shell/llm-agents.nix`. That file was preserved and is excluded from this focused commit.

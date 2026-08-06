# Task 3 implementation report

## Status

Task 3 completed in the existing worktree. The prior uncommitted Zsh tree was preserved and reviewed in place.

## Implementation

- Added an optional Home Manager Zsh aspect in `modules/shell/zsh.nix`; it does not alter any default shell setting.
- Installed `pkgs.zsh-abbr` once and loaded its managed user abbreviations once.
- Loaded generated `env.d` files and recursively loaded `conf.d` `.zsh`/`.sh` files with Zsh's deterministic lexical/numeric glob order.
- Kept the existing XDG and secrets bridge files as consumers; no platform bridge, user, VCS, Pet, or Herdr module was edited.
- Completed the Zsh aliases/functions/options/personal helpers and optional BAT, Chez Moi, Herdr, JJ, Pet, Yazi, sk-git, and skim integrations.
- Restored the current source sk-git picker set and full current abbreviation set from the sibling `dotfiles` repository.
- Guarded optional commands and non-repository picker paths. Picker insertion uses shell quoting and `zle reset-prompt`.
- Did not recreate deleted fzf integration or add a second skim package declaration.
- Recorded the existing Zsh consumer for rollout: `modules/users/micha.nix` selects `(<den/user-shell> "zsh")`; the user include remains intentionally owned by rollout Task 6.

## Verification

- `nix-instantiate --parse modules/shell/zsh.nix`: exit 0.
- Pinned `nix shell nixpkgs#zsh` plus `zsh -n` over every installed Zsh `.sh`, `.zsh`, and `.bak` file: exit 0; empty diagnostic output.
- Clean startup smoke test with `env -i HOME="$HOME" PATH="$PATH" zsh -d -f`, sourcing the rendered conf.d tree with optional commands absent: exit 0.
- Missing-command guard smoke test for sk-git, skim, and Pet with `PATH=/nonexistent`: exit 0 and no startup error.
- `git diff --check`: passed after removing generated blank-line warnings.
- Deleted fzf path check: no `fzf` files found under `dots/config/zsh`.
- Unresolved-template check: no Go-template, Chez Moi, OnePassword, or `.shell_env` delimiters in the Task 3 Zsh tree.

## Concerns

- A full Home Manager/NixOS evaluation was not run because the local Nix daemon socket is sandbox-restricted; module syntax parsing and the required shell checks passed using the pinned Nix Zsh package.
- The Zsh module is optional and is not included in user modules by this task, as required.

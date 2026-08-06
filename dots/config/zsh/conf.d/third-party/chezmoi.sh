if (( $+commands[chezmoi] && $+commands[nvim] )); then
  nvdot() { command nvim "${XDG_DATA_HOME:-$HOME/.local/share}/chezmoi" "$@"; }
fi

if (( $+commands[pet] )); then
  alias pexec='pet exec -t'
  alias psc='pet search'
fi
if [[ -o interactive ]] && (( $+commands[pet] && $+commands[sk] && $+functions[zle] )); then
  pet-select() { BUFFER=$(pet search --query "$LBUFFER"); CURSOR=$#BUFFER; zle reset-prompt 2>/dev/null || true; }
  zle -N pet-select
  bindkey '^f' pet-select; bindkey -M viins '^f' pet-select; bindkey -M vicmd '^f' pet-select
fi

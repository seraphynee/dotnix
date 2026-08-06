alias cl='clear'
alias c='clear'
alias chz='chezmoi'
alias nv='nvim'
alias oct='OPENCODE_CONFIG_DIR="$HOME/.config/opencode-thinking" opencode'
alias lzg='lazygit'
alias lzd='lazydocker'
alias mux='tmuxinator'
alias fier='tmuxifier'
alias ax='chmod a+x'
alias untar='tar -zxvf'
alias mktar='tar -cvzf'
alias numfiles='echo $(ls -1 | wc -l)'
alias pue='pueue'
alias pueon='pueued -d'
alias puer='pueue reset'
alias dotf='cd "${XDG_DATA_HOME:-$HOME/.local/share}/chezmoi"'
alias conf='cd "${XDG_CONFIG_HOME:-$HOME/.config}"'
alias exz='exec zsh'
alias restart-kanata='sudo launchctl kickstart -k system/com.example.kanata'
alias ping='gping'
if (( $+commands[wl-copy] )); then
  cpwd() { printf '%s' "$PWD" | wl-copy; }
elif (( $+commands[pbcopy] )); then
  cpwd() { printf '%s' "$PWD" | pbcopy; }
fi

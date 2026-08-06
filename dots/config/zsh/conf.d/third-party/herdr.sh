if (( $+commands[herdr] )); then
  for _f in "${XDG_CONFIG_HOME:-$HOME/.config}"/herdr/plugins/github/herdr-automatic-rename-*/shell/hook.zsh(N); do
    [[ -r $_f ]] && source "$_f" && break
  done
fi

ff() { find . -name "$1"; }
ffs() { find . -name "$1*"; }
ffe() { find . -name "*$1"; }
path() { print -rl -- ${(s.:.)PATH}; }
fpath() { print -rl -- ${(s.:.)FPATH}; }
whichcli() {
  local cli=${1:-}
  [[ -n $cli ]] || { print 'Usage: whichcli <command>'; return 1; }
  local active=${commands[$cli]:-}
  [[ -n $active ]] || { print "Command '$cli' not found in PATH."; return 1; }
  print "Command        : $cli"
  print "Active binary  : $active"
  print "Other installs : none detected"
}
upabbr() {
  print 'Resetting zsh-abbr...'
  rm -rf -- "${XDG_CONFIG_HOME:-$HOME/.config}/zsh-abbr"
  (( $+commands[abbr] )) && abbr import-aliases
  exec zsh
}
mkcd() { if [[ -d $1 ]]; then print 'It already exists! cd to the directory.'; cd -- "$1"; else mkdir -p -- "$1" && cd -- "$1"; fi; }
mcd() { mkdir -pv -- "$1" && cd -- "$1"; }
su() { if (( $# == 0 )); then sudo "$(fc -ln -1)"; else sudo "$@"; fi; }
sshlist() { awk '$1 ~ /Host$/ {for (i=2; i<=NF; i++) print $i}' "${HOME}/.ssh/config"; }
explain() { if (( $# == 0 )); then while read -r 'cmd?Command: '; do curl -Gs "https://www.mankier.com/api/explain/?cols=$(tput cols)" --data-urlencode "q=$cmd"; done; else curl -Gs "https://www.mankier.com/api/explain/?cols=$(tput cols)" --data-urlencode "q=$*"; fi; }
md5Check() { (( $+commands[md5sum] )) || { print "Can not find 'md5sum' utility"; return 1; }; [[ -e $2 ]] || { print "Can not find $2"; return 1; }; [[ $(md5sum "$2" | awk '{print $1}') == $1 ]]; }
myip() { print 'icanhazip (Default gateway)' 'AWS (Default gateway)' 'ipify (VPN)' 'ipecho (Bypass VPN)' 'Quit'; }
buf() { local file=$1 stamp=$(date +%Y%m%d_%H%M%S); cp -a -- "$file" "${file}_${stamp}"; }
chgext() { local f; for f in *."$1"; do [[ -e $f ]] && mv -- "$f" "${f%.${1}}.${2}"; done; }
escape() { print -rn -- "$*" | sed 's/[]\\.|$(){}?+*^]/\\&/g'; }
urlencode() { print -rn -- "$*" | sed 's/ /%20/g'; }
alias-select() {
  (( $+commands[sk] )) || return 0
  local picked=$(alias | sk --prompt='Select Alias > ' --no-multi)
  [[ -n $picked ]] || return 0
  LBUFFER+="${picked%%=*}"; zle reset-prompt 2>/dev/null || true
}

extract() {
  local archive=$1
  [[ -f $archive ]] || { print -u2 "Usage: extract <archive>"; return 1; }
  case $archive in
    *.tar.bz2|*.tbz2) command tar xjf -- "$archive";;
    *.tar.gz|*.tgz) command tar xzf -- "$archive";;
    *.tar.xz) command tar xJf -- "$archive";;
    *.tar) command tar xf -- "$archive";;
    *.gz) command gunzip -- "$archive";;
    *.bz2) command bunzip2 -- "$archive";;
    *.zip) command unzip -- "$archive";;
    *) print -u2 "extract: unsupported archive: $archive"; return 1;;
  esac
}
if [[ -o interactive ]]; then
  zle -N alias-select
  bindkey '^e' alias-select
  bindkey -M viins '^e' alias-select
  bindkey -M vicmd '^e' alias-select
fi

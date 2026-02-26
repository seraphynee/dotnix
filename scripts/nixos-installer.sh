#!/bin/zsh -f

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "$0")" && pwd)"
REPO_ROOT="$(cd -- "$SCRIPT_DIR/.." && pwd)"

if ! command -v gum >/dev/null 2>&1; then
	print -u2 "Error: 'gum' was not found in PATH."
	print -u2 "Please install it first: https://github.com/charmbracelet/gum"
	exit 127
fi

# Default values (can be overridden via environment variables)
IP_TARGET_HOST="${IP_TARGET_HOST:-192.168.100.13}"
KEY_FILE="${KEY_FILE:-$HOME/keys.txt}"
FLAKE_HOST="${FLAKE_HOST:-esquire}"
TARGET_USER="${TARGET_USER:-root}"
BUILD_ON="${BUILD_ON:-remote}"
SSH_PREFERRED_AUTH="${SSH_PREFERRED_AUTH:-password}"
SSH_DISABLE_PUBKEY="${SSH_DISABLE_PUBKEY:-yes}"

print
gum style --border normal --padding "1 2" --margin "1 0" \
	"NixOS Installer" \
	"Fill in the options below to run nixos-anywhere."

IP_TARGET_HOST="$(gum input \
	--prompt "IP target host: " \
	--placeholder "192.168.100.13" \
	--value "$IP_TARGET_HOST")"

KEY_FILE="$(gum input \
	--prompt "Path keyfile: " \
	--placeholder "$HOME/keys.txt" \
	--value "$KEY_FILE")"

FLAKE_HOST="$(gum input \
	--prompt "Flake host: " \
	--placeholder "esquire" \
	--value "$FLAKE_HOST")"

TARGET_HOST="${TARGET_USER}@${IP_TARGET_HOST}"
FLAKE="${REPO_ROOT}#${FLAKE_HOST}"

gum style --margin "1 0" "Selected configuration:"
gum style "  target-host : ${TARGET_HOST}"
gum style "  keyfile     : ${KEY_FILE}"
gum style "  flake       : ${FLAKE}"
gum style "  build-on    : ${BUILD_ON}"
gum style "  ssh auth    : ${SSH_PREFERRED_AUTH}"

if ! gum confirm "Continue installation on this host?"; then
	print "Cancelled."
	exit 0
fi

if command -v nixos-anywhere >/dev/null 2>&1; then
	na_cmd=(nixos-anywhere)
elif command -v nix >/dev/null 2>&1; then
	na_cmd=(nix run github:nix-community/nixos-anywhere --)
else
	print -u2 "Error: nix and nixos-anywhere were not found in PATH."
	print -u2 "Make sure Nix is installed, then run this script again."
	exit 127
fi

if [[ ! -f "$KEY_FILE" ]]; then
	print -u2 "Error: key file not found: $KEY_FILE"
	exit 1
fi

tmp="$(mktemp -d)"
cleanup() { rm -rf "$tmp"; }
trap cleanup EXIT INT TERM

mkdir -p "$tmp/var/lib/sops-nix"
cp "$KEY_FILE" "$tmp/var/lib/sops-nix/keys.txt"
chmod 600 "$tmp/var/lib/sops-nix/keys.txt"

"${na_cmd[@]}" \
	--flake "$FLAKE" \
	--build-on "$BUILD_ON" \
	--extra-files "$tmp" \
	--ssh-option "PreferredAuthentications=${SSH_PREFERRED_AUTH}" \
	--ssh-option "PubkeyAuthentication=${SSH_DISABLE_PUBKEY}" \
	"$TARGET_HOST"

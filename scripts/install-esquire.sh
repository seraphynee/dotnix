#!/bin/zsh -f

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "$0")" && pwd)"
REPO_ROOT="$(cd -- "$SCRIPT_DIR/.." && pwd)"

# Bisa dioverride via environment variable
KEY_FILE="${KEY_FILE:-$HOME/keys.txt}"
TARGET_HOST="${TARGET_HOST:-root@192.168.100.13}"
FLAKE="${FLAKE:-${REPO_ROOT}#esquire}"
BUILD_ON="${BUILD_ON:-remote}"
SSH_PREFERRED_AUTH="${SSH_PREFERRED_AUTH:-publickey,password}"

if command -v nixos-anywhere >/dev/null 2>&1; then
	na_cmd=(nixos-anywhere)
elif command -v nix >/dev/null 2>&1; then
	na_cmd=(nix run github:nix-community/nixos-anywhere --)
else
	print -u2 "Error: nix dan nixos-anywhere tidak ditemukan di PATH."
	print -u2 "Pastikan Nix terpasang, lalu jalankan ulang script ini."
	exit 127
fi

if [[ ! -f "$KEY_FILE" ]]; then
	print -u2 "Error: file key tidak ditemukan: $KEY_FILE"
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
	"$TARGET_HOST"

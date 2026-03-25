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
KEY_FILE="${KEY_FILE:-$HOME/.local/share/ages/keys.txt}"
FLAKE_HOST="${FLAKE_HOST:-esquire-installer}"
TARGET_USER="${TARGET_USER:-root}"
BUILD_ON="${BUILD_ON:-remote}"
SSH_AUTH_MODE="${SSH_AUTH_MODE:-password}"
SSH_KEY_DIR="${SSH_KEY_DIR:-$HOME/.ssh_keys}"
SSH_KEY_NAME="${SSH_KEY_NAME:-id_ed25519}"
SSH_KEY_FILE=""
SSH_PUBKEY_FILE=""

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
	--placeholder "$HOME/.local/share/ages/keys.txt" \
	--value "$KEY_FILE")"

FLAKE_HOST="$(gum input \
	--prompt "Flake host: " \
	--placeholder "esquire-installer" \
	--value "$FLAKE_HOST")"

SSH_AUTH_CHOICE="$(gum choose \
	"Password only" \
	"Bootstrap SSH key")"

if [[ "$SSH_AUTH_CHOICE" == "Bootstrap SSH key" ]]; then
	SSH_AUTH_MODE="key"
	SSH_KEY_NAME="$(gum input \
		--prompt "SSH key name: " \
		--placeholder "id_ed25519" \
		--value "$SSH_KEY_NAME")"
	SSH_KEY_FILE="${SSH_KEY_DIR}/${SSH_KEY_NAME}"
	SSH_PUBKEY_FILE="${SSH_KEY_FILE}.pub"
else
	SSH_AUTH_MODE="password"
fi

TARGET_HOST="${TARGET_USER}@${IP_TARGET_HOST}"
FLAKE="${REPO_ROOT}#${FLAKE_HOST}"

gum style --margin "1 0" "Selected configuration:"
gum style "  target-host : ${TARGET_HOST}"
gum style "  keyfile     : ${KEY_FILE}"
gum style "  flake       : ${FLAKE}"
gum style "  build-on    : ${BUILD_ON}"
if [[ "$SSH_AUTH_MODE" == "password" ]]; then
	gum style "  ssh mode    : password only"
else
	gum style "  ssh mode    : bootstrap ssh key"
	gum style "  ssh key dir : ${SSH_KEY_DIR}"
	gum style "  ssh key     : ${SSH_KEY_NAME}"
	gum style "  ssh privkey : ${SSH_KEY_FILE}"
	gum style "  ssh pubkey  : ${SSH_PUBKEY_FILE}"
fi

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

if [[ "$SSH_AUTH_MODE" == "key" ]]; then
	if [[ ! -f "$SSH_KEY_FILE" ]]; then
		print -u2 "Error: SSH private key file not found: $SSH_KEY_FILE"
		exit 1
	fi

	if [[ ! -f "$SSH_PUBKEY_FILE" ]]; then
		print -u2 "Error: SSH public key file not found: $SSH_PUBKEY_FILE"
		exit 1
	fi
fi

ssh_options=()
if [[ "$SSH_AUTH_MODE" == "password" ]]; then
	ssh_options=(
		--ssh-option "PreferredAuthentications=password"
		--ssh-option "PubkeyAuthentication=no"
	)
else
	ssh_options=(
		--ssh-option "PreferredAuthentications=publickey"
		--ssh-option "PubkeyAuthentication=yes"
		--ssh-option "PasswordAuthentication=no"
		--ssh-option "IdentityFile=${SSH_KEY_FILE}"
		--ssh-option "IdentitiesOnly=yes"
	)
fi

if [[ "$SSH_AUTH_MODE" == "key" ]]; then
	gum style --margin "1 0" \
		"Bootstrapping SSH key to ${TARGET_HOST}" \
		"Enter the current root password on the target when prompted."

	if command -v ssh-copy-id >/dev/null 2>&1; then
		ssh-copy-id \
			-i "$SSH_PUBKEY_FILE" \
			-o PreferredAuthentications=password \
			-o PubkeyAuthentication=no \
			"$TARGET_HOST"
	else
		pubkey_contents="$(<"$SSH_PUBKEY_FILE")"
		ssh \
			-o PreferredAuthentications=password \
			-o PubkeyAuthentication=no \
			"$TARGET_HOST" \
			"umask 077; mkdir -p ~/.ssh; grep -qxF '$pubkey_contents' ~/.ssh/authorized_keys 2>/dev/null || printf '%s\n' '$pubkey_contents' >> ~/.ssh/authorized_keys"
	fi
fi

tmp="$(mktemp -d)"
cleanup() { rm -rf "$tmp"; }
trap cleanup EXIT INT TERM

mkdir -p "$tmp/var/lib/sops-nix"
cp "$KEY_FILE" "$tmp/var/lib/sops-nix/keys.txt"
chmod 600 "$tmp/var/lib/sops-nix/keys.txt"

mkdir -p "$tmp/persist/var/lib/sops-nix"
cp "$KEY_FILE" "$tmp/persist/var/lib/sops-nix/keys.txt"
chmod 600 "$tmp/persist/var/lib/sops-nix/keys.txt"

"${na_cmd[@]}" \
	--flake "$FLAKE" \
	--build-on "$BUILD_ON" \
	--extra-files "$tmp" \
	"${ssh_options[@]}" \
	"$TARGET_HOST"

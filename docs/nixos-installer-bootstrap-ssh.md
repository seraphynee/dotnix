# Remote NixOS Installation with Bootstrap SSH Key

This document describes the remote installation flow used by `scripts/nixos-installer.sh`.

The intended flow is:

1. Set a temporary `root` password on the target machine running the NixOS live installer.
2. Start SSH on the target machine.
3. Run the installer script from the source machine.
4. Let the script copy the SSH public key to the target machine.
5. Continue the installation using SSH key authentication.

## Prerequisites

- The target machine is already booted into a NixOS live installer or live USB environment.
- The source machine can reach the target machine over the network.
- You know the target machine IP address.
- You know which host name to install from this flake, for example `esquire`.
- You have the `sops-nix` age key file on the source machine.
- You have an SSH key pair on the source machine in this location:
  - private key: `~/.ssh_keys/<ssh_key_name>`
  - public key: `~/.ssh_keys/<ssh_key_name>.pub`
- `gum` is installed on the source machine.
- Either `nixos-anywhere` or `nix` is installed on the source machine.
- The target disk and host configuration have already been reviewed before installation.

## What Need To Do

### Target Machine

Run these commands on the target machine from the live installer shell:

```bash
passwd
systemctl start sshd
systemctl status sshd
ip addr
```

What this does:

- `passwd` sets the temporary `root` password used for the initial SSH bootstrap.
- `systemctl start sshd` starts the SSH server.
- `systemctl status sshd` verifies that the SSH server is running.
- `ip addr` shows the target machine IP address.

Important notes:

- Set the password for `root`, not for the `nixos` user.
- The script connects to `root@<target-ip>` by default.
- The target machine must allow SSH login for `root` with password at least for the initial bootstrap step.

### Source Machine

Run these commands on the source machine:

```bash
ls -l ~/.ssh_keys
test -f ~/.ssh_keys/<ssh_key_name>
test -f ~/.ssh_keys/<ssh_key_name>.pub
test -f ~/.local/ages/keys.txt
./scripts/nixos-installer.sh
```

What to enter in the installer prompt:

- `IP target host`: the IP address shown on the target machine
- `Path keyfile`: the local age key file, for example `~/.local/ages/keys.txt`
- `Flake host`: the host defined in this repository, for example `esquire`
- `SSH mode`: choose `Bootstrap SSH key`
- `SSH key name`: only the key name, for example `id_ed25519`

What the script does in `Bootstrap SSH key` mode:

1. It reads the SSH private key from `~/.ssh_keys/<ssh_key_name>`.
2. It reads the SSH public key from `~/.ssh_keys/<ssh_key_name>.pub`.
3. It connects to `root@<target-ip>` using password authentication.
4. It copies the public key to the target machine `~/.ssh/authorized_keys`.
5. It runs `nixos-anywhere` using SSH key authentication only.

## Example

Example target machine session:

```bash
passwd
systemctl start sshd
ip addr
```

Example source machine session:

```bash
test -f ~/.ssh_keys/id_ed25519
test -f ~/.ssh_keys/id_ed25519.pub
test -f ~/.local/ages/keys.txt
./scripts/nixos-installer.sh
```

Then enter:

- target IP: `192.168.100.13`
- key file: `~/.local/ages/keys.txt`
- flake host: `esquire`
- SSH mode: `Bootstrap SSH key`
- SSH key name: `id_ed25519`

## Result

If everything succeeds:

- the SSH public key is added to the target machine for `root`
- `nixos-anywhere` installs the selected flake host
- the installation uses SSH key authentication after the bootstrap step

## Troubleshooting

If the script cannot connect:

- verify that `sshd` is running on the target machine
- verify that the target IP address is correct
- verify that the `root` password was set successfully
- verify that the source machine can reach the target machine over the network

If the script fails before copying the key:

- verify that `~/.ssh_keys/<ssh_key_name>` exists
- verify that `~/.ssh_keys/<ssh_key_name>.pub` exists
- verify that the age key file path is correct

If the installation fails after the key bootstrap step:

- verify that the selected flake host is correct
- verify that the disk configuration for the target host is correct

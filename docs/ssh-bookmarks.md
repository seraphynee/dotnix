# SSH Bookmarks and 1Password Agent

SSH bookmark metadata is declared in
[`data/ssh/bookmarks.nix`](../data/ssh/bookmarks.nix). The `hosts` entries are
rendered through Home Manager's `programs.ssh.settings`; the default `Host *`
settings live under `defaults`.

Connection metadata such as aliases, routes, users, ports, and public
`IdentityFile` paths is intentionally non-secret. Private keys, credentials,
and other secret material remain managed by SOPS. The old encrypted
`ssh/config` payload is no longer included by the SOPS module.

Each bookmark can opt into the 1Password SSH agent with
`useOpIdentityAgent = true`. The generated config adds an
`IdentityAgent` block scoped with `Match originalhost`. It also checks that
`SSH_TTY` is unset, so an SSH session on a remote machine keeps using its
forwarded agent instead of being overridden by the local 1Password socket.
Linux and macOS use their platform-specific 1Password socket paths.

Validate the generated configuration and forwarding behavior with:

```bash
nix build .#checks.x86_64-linux.ssh-bookmarks --print-build-logs
```

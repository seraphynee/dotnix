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
`SSH_CONNECTION` is unset. Unlike `SSH_TTY`, which is absent from SSH sessions
without a pseudo-terminal, `SSH_CONNECTION` is set for both interactive and
non-interactive SSH sessions. This keeps nested SSH and Git operations using a
forwarded agent instead of the remote machine's local 1Password socket. The
shell configuration deliberately does not set `SSH_AUTH_SOCK`, so it cannot
overwrite the socket supplied by agent forwarding. Linux and macOS use their
platform-specific 1Password socket paths.

The default host-key policy is `accept-new`: OpenSSH automatically records keys
for new hosts but rejects changed host keys. Agent forwarding remains enabled
only for the explicitly declared `tailacer` bookmark.

Validate the generated configuration and forwarding behavior with:

```bash
nix build .#checks.x86_64-linux.ssh-bookmarks --print-build-logs
```

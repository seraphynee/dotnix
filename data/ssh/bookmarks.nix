# Non-secret SSH connection metadata migrated from the encrypted SSH config.
# Keep private keys and credentials in SOPS; these values only describe how to
# reach each bookmark and which public key path the SSH agent should select.
#
# Bookmarks are grouped by role. Each attribute name is the final `Host` alias
# (Tailscale-routed machines use the `tail` prefix).
{
  defaults = {
    IdentitiesOnly = true;
    Protocol = 2;
    ServerAliveCountMax = 120;
    ServerAliveInterval = 30;
    StrictHostKeyChecking = "accept-new";
  };

  # Personal machines reached over Tailscale; agent forwarding allowed.
  workstations = {
    tailws-acer = {
      ForwardAgent = true;
      HostName = "100.66.28.81";
      IdentitiesOnly = true;
      IdentityFile = [ "~/.ssh_keys/acer.pub" ];
      Port = 22;
      useOpIdentityAgent = true;
      User = "chianyung";
    };

    # TODO: tailws-mbp and tailws-pc-nixos (User, Tailscale IP, Port, public key).
  };

  # Example:
  # tailds-atlas = { ForwardAgent = true; HostName = "100.x.y.z"; ... };
  development_servers = { };

  # Policy (enforced by nix/checks/ssh-bookmarks.nix): never forward the agent
  # and never use the local 1Password agent for deployment servers.
  deployment_servers = {
    # TODO: prod-hermes-oracle (User, HostName, Port, public key).
  };

  # Names are frozen: they are embedded in git remote URLs (e.g. ghcny:owner/repo.git).
  git_hosts = {
    ghcny = {
      HostName = "github.com";
      IdentitiesOnly = true;
      IdentityFile = [ "~/.ssh_keys/ghcny-auth.pub" ];
      Port = 22;
      useOpIdentityAgent = true;
      User = "git";
    };

    ghspy = {
      HostName = "github.com";
      IdentitiesOnly = true;
      IdentityFile = [ "~/.ssh_keys/ghspy-auth.pub" ];
      Port = 22;
      useOpIdentityAgent = true;
      User = "git";
    };

    glcny = {
      HostName = "gitlab.com";
      IdentitiesOnly = true;
      IdentityFile = [ "~/.ssh_keys/glcny-auth.pub" ];
      Port = 22;
      useOpIdentityAgent = true;
      User = "git";
    };
  };
}

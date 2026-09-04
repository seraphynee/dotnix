# Non-secret SSH connection metadata migrated from the encrypted SSH config.
# Keep private keys and credentials in SOPS; these values only describe how to
# reach each bookmark and which public key path the SSH agent should select.
{
  defaults = {
    IdentitiesOnly = true;
    Protocol = 2;
    ServerAliveCountMax = 120;
    ServerAliveInterval = 30;
    StrictHostKeyChecking = "accept-new";
  };

  hosts = {
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

    tailacer = {
      ForwardAgent = true;
      HostName = "100.66.28.81";
      IdentitiesOnly = true;
      IdentityFile = [ "~/.ssh_keys/acer.pub" ];
      Port = 22;
      useOpIdentityAgent = true;
      User = "chianyung";
    };
  };
}

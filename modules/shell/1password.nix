{ constants, ... }:
{
  den.aspects.shell._._1password = {
    nixos = {
      environment.etc = {
        "1password/custom_allowed_browsers" = {
          text = ''
            zen
          ''; # or just "zen" if you use unwrapped package
          mode = "0755";
        };
      };

      programs._1password.enable = true;
      programs._1password-gui = {
        enable = true;
        # Certain features, including CLI integration and system authentication support,
        # require enabling PolKit integration on some desktop environments (e.g. Plasma).
        polkitPolicyOwners = [ "${constants.user.seraphynee.username}" ];
      };
    };
    homeManager =
      { lib, ... }:
      {
        xdg.configFile."1Password/ssh/agent.toml".source = ../../dots/config/1Password/ssh/agent.toml;
        # Prevent Home Manager's ssh-agent service from overriding SSH_AUTH_SOCK.
        services.ssh-agent = {
          enable = lib.mkForce false;
        };
        programs.ssh.enable = true;
      };
  };
}

{ constants, ... }:
{
  den.aspects.shell._._1password = {
    nixos = {
      programs._1password.enable = true;
      programs._1password-gui = {
        enable = true;
        # Certain features, including CLI integration and system authentication support,
        # require enabling PolKit integration on some desktop environments (e.g. Plasma).
        polkitPolicyOwners = [ "${constants.user_two}" ];
      };
    };
    homeManager =
      {
        pkgs,
        lib,
        ...
      }:
      {
        xdg.configFile."1Password/ssh/agent.toml".source = ../../dots/config/1Password/ssh/agent.toml;
        # Prevent Home Manager's ssh-agent service from overriding SSH_AUTH_SOCK.
        services.ssh-agent = {
          enable = lib.mkForce false;
          enableFishIntegration = lib.mkForce false;
          enableNushellIntegration = lib.mkForce false;
        };
        home.sessionVariables =
          lib.optionalAttrs (pkgs.stdenv.hostPlatform.isDarwin || pkgs.stdenv.hostPlatform.isLinux)
            {
              SSH_AUTH_SOCK =
                if pkgs.stdenv.hostPlatform.isDarwin then
                  "$HOME/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"
                else
                  "$HOME/.1password/agent.sock";
            };
        programs.ssh.enable = true;
      };
  };
}

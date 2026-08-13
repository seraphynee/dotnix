{
  den.aspects.system._.networking = {
    nixos = {
      networking = {
        networkmanager.enable = true;
        nameservers = [
          "1.1.1.1" # Cloudflare
          "8.8.8.8" # Google
        ];
      };
    };
  };

  den.aspects.system._.ssh = {
    nixos = { };
    homeManager = {
      programs.ssh = {
        enableDefaultConfig = false;
        settings."*" = { };
      };
    };
  };

  den.aspects.system._.sshd = {
    nixos = {
      services.sshd.enable = true;
      services.openssh = {
        enable = true;
        settings = {
          AllowAgentForwarding = "yes";
          PasswordAuthentication = false;
          KbdInteractiveAuthentication = false;
          PermitRootLogin = "no";
        };
      };
    };

    provides = {
      forward-ports.nixos = {
        virtualisation.vmVariant.virtualisation.forwardPorts = [
          {
            host.port = 2222;
            guest.port = 22;
          }
        ];
      };
    };
  };
}

{
  __findFile,
  constants,
  ...
}:
{
  den.homes.x86_64-linux.${constants.user.seraphynee.username} = { };

  den.aspects.${constants.user.seraphynee.username} = {
    includes = [
      <den/host-aspects>
      <den/primary-user>

      (<den/user-shell> "fish")

      <feature/development>
      <feature/personal>
    ];

    homeManager.dotnix.repositories = {
      enable = true;
      entries = import ../../data/repositories/seraphynee.nix;
    };

    homeManager.dotnix.vcs = {
      identity = {
        name = constants.user.seraphynee.gitUser;
        email = constants.user.seraphynee.email;
      };
      github = {
        username = constants.user.seraphynee.gitUser;
        patSecret = "keys/pat/ghspy-pat";
      };
      signing.keySecret = "keys/ssh/github/signing/ghspy-pub";
      git.enable = true;
      jujutsu = {
        enable = true;
        workstation = true;
      };
    };

    nixos =
      {
        config,
        ...
      }:
      {
        users.users.${constants.user.seraphynee.username} = {
          extraGroups = [
            "incus-admin"
            "input"
            "uinput"
          ];

          hashedPasswordFile = config.sops.secrets."passwords/${constants.user.seraphynee.username}".path;
          openssh.authorizedKeys.keys = [
            "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICspqdai1ehCDaPlUvuhCfS8/mTGNc87NkwMlta0Jzg/"
          ];
        };
      };
  };
}

{
  __findFile,
  constants,
  ...
}:
{
  den.homes.x86_64-linux.${constants.users.admin} = { };

  den.aspects.${constants.users.admin} = {
    includes = [
      <den/host-aspects>
      <den/primary-user>

      (<den/user-shell> "zsh")
    ];

    nixos =
      {
        config,
        ...
      }:
      {
        users.users.${constants.users.admin} = {

          hashedPasswordFile = config.sops.secrets."passwords/admin".path;
          openssh.authorizedKeys.keys = [
            "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEbgd1yxIEILCc2/92f8NEnE1FwJ6XqFJVR2CQ3aj92y"
          ];
        };
      };
  };
}

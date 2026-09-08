{
  __findFile,
  constants,
  ...
}:
{
  den.aspects.${constants.user.micha.username} = {
    includes = [
      <den/host-aspects>
      (<den/user-shell> "zsh")
      <shell/zsh>
      <feature/development>
    ];

    nixos =
      {
        config,
        ...
      }:
      {
        users.users.${constants.user.micha.username} = {
          extraGroups = [
            "uinput"
          ];

          hashedPasswordFile = config.sops.secrets."passwords/${constants.user.micha.username}".path;
          openssh.authorizedKeys.keys = [
            "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDRu2lSAzPbNC4T1ztmHLNPw81tqyoVTCBg1+uv3PGG5"
          ];
        };
      };
  };
}

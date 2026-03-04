{
  __findFile,
  constants,
  ...
}:
{
  # den.homes.x86_64-linux.${constants.user_one} = { };
  # den.homes.aarch64-darwin.${constants.user_one} = { };

  den.aspects.${constants.user_one} = {
    includes = [
      <den/primary-user>

      <shell/nix-tools>
    ];

    nixos =
      {
        pkgs,
        lib,
        config,
        ...
      }:
      {
        users.users.${constants.user_one} = {
          extraGroups = [
            "uinput"
          ];

          hashedPasswordFile = config.sops.secrets."passwords/chianyung".path;
          openssh.authorizedKeys.keys = [
            "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAr35LjSF5Av8xcsrswXznvBwt4CNDhtD97IqZp0H4/n"
          ];
        };
      };
  };
}

{
  __findFile,
  constants,
  ...
}:
{
  den.aspects.${constants.user.chianyung.username} = {
    includes = [
      <den/host-aspects>
      <den/primary-user>

      <shell/formatters>
      <shell/vcs>
      <shell/nix-tools>
    ];

    homeManager.dotnix.vcs = {
      identity = {
        name = constants.user.chianyung.git_user;
        email = constants.user.chianyung.email;
      };
      github.username = constants.user.chianyung.git_user;
      signing.keySecret = "keys/ssh/github/signing/ghcny-pub";
      git.enable = true;
    };

    darwin =
      { config, ... }:
      {
        nix.settings.trusted-users = [
          "root"
          "@wheel"
          constants.user.chianyung.username
        ];
      };

    nixos =
      {
        pkgs,
        lib,
        config,
        ...
      }:
      {
        users.users.${constants.user.chianyung.username} = {
          extraGroups = [
            "uinput"
          ];

          hashedPasswordFile = config.sops.secrets."passwords/${constants.user.chianyung.username}".path;
          openssh.authorizedKeys.keyFiles = [
            config.sops.secrets."keys/ssh/workstation/users/${constants.user.chianyung.username}".path
          ];
        };
      };
  };
}

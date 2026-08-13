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
      <den/host-aspects>
      <den/primary-user>

      <shell/vcs>
      <shell/nix-tools>
    ];

    homeManager.dotnix.vcs = {
      identity = {
        name = "chianyungcode";
        email = "cnytechcode@gmail.com";
      };
      github.username = "chianyungcode";
      signing.keySecret = "keys/ssh/github/signing/ghcny-pub";
      git.enable = true;
    };

    darwin =
      { config, ... }:
      {
        nix.settings.trusted-users = [
          "root"
          "@wheel"
          constants.user_one
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
        users.users.${constants.user_one} = {
          extraGroups = [
            "uinput"
          ];

          hashedPasswordFile = config.sops.secrets."passwords/${constants.user_one}".path;
          openssh.authorizedKeys.keyFiles = [
            config.sops.secrets."keys/ssh/workstation/users/${constants.user_one}".path
          ];
        };
      };
  };
}

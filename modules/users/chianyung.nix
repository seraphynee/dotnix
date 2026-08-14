{
  __findFile,
  constants,
  ...
}:
{
  den.aspects.${constants.users.chianyung} = {
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
          constants.users.chianyung
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
        users.users.${constants.users.chianyung} = {
          extraGroups = [
            "uinput"
          ];

          hashedPasswordFile = config.sops.secrets."passwords/${constants.users.chianyung}".path;
          openssh.authorizedKeys.keyFiles = [
            config.sops.secrets."keys/ssh/workstation/users/${constants.users.chianyung}".path
          ];
        };
      };
  };
}

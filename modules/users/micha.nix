{
  __findFile,
  constants,
  ...
}:
{
  # den.homes.x86_64-linux.${constants.user_three} = { };

  den.aspects.${constants.user_three} = {
    includes = [
      # Automatically set default shell
      (<den/user-shell> "zsh")

      <shell/packages/dev>
      <shell/packages/personal>
      <shell/nix-tools>

      <shell/_1password>
      <shell/ai>
      <shell/bash>
      <shell/env>
      <shell/fish>
      <shell/git>
      <shell/lazygit>
      <shell/nh>
      <shell/neovim>
      <shell/starship>
      <shell/tmux>
      <shell/utils>
    ];

    nixos =
      {
        config,
        ...
      }:
      {
        users.users.${constants.user_three} = {
          extraGroups = [
            "uinput"
          ];

          hashedPasswordFile = config.sops.secrets."passwords/${constants.user_three}".path;
          openssh.authorizedKeys.keys = [
            "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDRu2lSAzPbNC4T1ztmHLNPw81tqyoVTCBg1+uv3PGG5"
          ];
        };
      };
  };
}

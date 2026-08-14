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

      <shell/packages/dev>
      <shell/packages/personal>
      <shell/nix-tools>

      <shell/_1password>
      <shell/ai>
      <shell/bash>
      <shell/env>
      <shell/fish>
      <shell/lazygit>
      <shell/nh>
      <shell/neovim>
      <shell/starship>
      <shell/tmux>
      <shell/utils>
      <shell/zsh>
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

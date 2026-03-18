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

      <shell/nix-tools>
      <shell/utils>
      <shell/packages/dev>
      <shell/nh>
      <shell/env>

      <shell/_1password>
      <shell/bash>
      <shell/fish>
      <shell/git>
      <shell/lazygit>
      <shell/neovim>
      <shell/starship>
      <shell/tmux>
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
          openssh.authorizedKeys.keyFiles = [
            config.sops.secrets."keys/ssh/workstation/users/${constants.user_three}".path
          ];
        };
      };
  };
}

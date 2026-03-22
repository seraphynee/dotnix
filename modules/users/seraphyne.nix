{
  __findFile,
  constants,
  ...
}:
{
  den.homes.x86_64-linux.${constants.user_two} = { };

  den.aspects.${constants.user_two} = {
    includes = [
      <den/primary-user>

      # Automatically set default shell
      (<den/user-shell> "fish")

      <shell/nix-tools>
      <shell/utils>
      <shell/packages/dev>
      <shell/nh>
      <shell/env>

      <shell/_1password>
      <shell/ai>
      <shell/bash>
      <shell/codex>
      <shell/fastfetch>
      <shell/fish>
      <shell/git>
      <shell/helix>
      <shell/jujutsu/seraphyne>
      <shell/lazygit>
      <shell/neovim>
      <shell/opencode>
      <shell/ocr>
      <shell/starship>
      <shell/tmux>
      <shell/yazi>
      <shell/zellij>
    ];

    nixos =
      {
        config,
        ...
      }:
      {
        users.users.${constants.user_two} = {
          extraGroups = [
            "uinput"
          ];

          hashedPasswordFile = config.sops.secrets."passwords/seraphyne".path;
          openssh.authorizedKeys.keyFiles = [
            config.sops.secrets."keys/ssh/workstation/users/seraphyne".path
          ];
        };
      };
  };
}

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

      <shell/packages/dev>
      <shell/packages/personal>
      <shell/nix-tools>

      <shell/_1password>
      <shell/ai>
      <shell/bash>
      <shell/codex>
      <shell/env>
      <shell/espanso>
      <shell/fastfetch>
      <shell/fish>
      <shell/git>
      <shell/helix>
      <shell/jujutsu/seraphyne>
      <shell/lazygit>
      <shell/nh>
      <shell/neovim>
      <shell/ocr>
      <shell/opencode>
      <shell/starship>
      <shell/tmux>
      <shell/utils>
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
          openssh.authorizedKeys.keys = [
            "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICspqdai1ehCDaPlUvuhCfS8/mTGNc87NkwMlta0Jzg/"
          ];
        };
      };
  };
}

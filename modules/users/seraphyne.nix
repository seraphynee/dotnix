{
  __findFile,
  constants,
  ...
}:
{
  den.homes.x86_64-linux.${constants.user_two} = { };

  den.aspects.${constants.user_two} = {
    includes = [
      <den/host-aspects>
      <den/primary-user>

      # Automatically set default shell
      (<den/user-shell> "fish")

      <shell/packages/dev>
      <shell/packages/personal>
      <shell/nix-tools>

      <shell/_1password>
      <shell/ai>
      <shell/bash>
      <shell/env>
      <shell/espanso>
      <shell/fastfetch>
      <shell/fish>
      <shell/git>
      <shell/helix>
      <shell/herdr>
      <shell/hunk>
      <shell/jujutsu/seraphyne>
      <shell/lazygit>
      <shell/llm_agents>
      <shell/my-scripts>
      <shell/nh>
      <shell/neovim>
      <shell/ocr>
      <shell/opencommit>
      <shell/starship>
      <shell/tmux>
      <shell/utils>
      <shell/worktrunk>
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
            "input"
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

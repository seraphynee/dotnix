{
  __findFile,
  constants,
  ...
}:
{
  den.homes.x86_64-linux.${constants.user.seraphynee.username} = { };

  den.aspects.${constants.user.seraphynee.username} = {
    includes = [
      <den/host-aspects>
      <den/primary-user>

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
      <shell/vcs>
      <shell/helix>
      <shell/herdr>
      <shell/hunk>
      <shell/lazygit>
      <shell/lla>
      <shell/llm_agents>
      <shell/my-scripts>
      <shell/nano>
      <shell/nh>
      <shell/neovim>
      <shell/ocr>
      <shell/opencommit>
      <shell/pet>
      <shell/starship>
      <shell/superfile>
      <shell/television>
      <shell/tmux>
      <shell/utils>
      <shell/worktrunk>
      <shell/yazi>
      <shell/zellij>
    ];

    homeManager.dotnix.vcs = {
      identity = {
        name = constants.user.seraphynee.git_user;
        email = constants.user.seraphynee.email;
      };
      github = {
        username = constants.user.seraphynee.git_user;
        patSecret = "keys/pat/ghspy-pat";
      };
      signing.keySecret = "keys/ssh/github/signing/ghspy-pub";
      git.enable = true;
      jujutsu = {
        enable = true;
        workstation = true;
      };
    };

    nixos =
      {
        config,
        ...
      }:
      {
        users.users.${constants.user.seraphynee.username} = {
          extraGroups = [
            "input"
            "uinput"
          ];

          hashedPasswordFile = config.sops.secrets."passwords/${constants.user.seraphynee.username}".path;
          openssh.authorizedKeys.keys = [
            "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICspqdai1ehCDaPlUvuhCfS8/mTGNc87NkwMlta0Jzg/"
          ];
        };
      };
  };
}

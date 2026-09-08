{ __findFile, ... }:
{
  den.aspects.feature._.development = {
    description = "Shared interactive development environment";

    includes = [
      <shell/packages/dev>
      <shell/packages/personal>
      <shell/nix-tools>

      <shell/_1password>
      <shell/ai>
      <shell/bash>
      <shell/env>
      <shell/fish>
      <shell/lazygit>
      <shell/neovim>
      <shell/nh>
      <shell/starship>
      <shell/tmux>
      <shell/utils>
    ];
  };
}

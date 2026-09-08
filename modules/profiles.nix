{ __findFile, ... }:
{
  den.aspects.profile._.workstation = {
    description = "Shared workstation system, desktop, application, and service capabilities";

    includes = [
      <system/audio>
      <system/fonts>
      <system/locale>
      <system/networking>
      <system/settings>
      <system/ssh>
      <system/sshd>
      <system/virt>
      <system/xdg>

      <desktop/wm/mango>
      <desktop/qs/noctalia>

      <apps/chromium>
      <apps/discord>
      <apps/firefox>
      <apps/ghostty>
      <apps/wezterm>
      <apps/zed>
      <apps/zen>

      <services/kanata>
      <services/tailscale>
    ];
  };

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

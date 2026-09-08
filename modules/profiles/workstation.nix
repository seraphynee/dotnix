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
}

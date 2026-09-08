{ __findFile, ... }:
{
  den.aspects.feature._.personal = {
    description = "Personal applications, services, and interactive workflow";

    includes = [
      <services/cloudflare-warp>

      <apps/datagrip>
      <apps/vscode>

      <shell/_1password>
      <shell/packages/personal>

      <shell/espanso>
      <shell/fastfetch>
      <shell/formatters>
      <shell/vcs>
      <shell/helix>
      <shell/herdr>
      <shell/hunk>
      <shell/lla>
      <shell/llm-agents>
      <shell/my-scripts>
      <shell/nano>
      <shell/ocr>
      <shell/opencommit>
      <shell/pet>
      <shell/superfile>
      <shell/television>
      <shell/workmux>
      <shell/worktrunk>
      <shell/yazi>
      <shell/zellij>
    ];
  };
}

{ lib, pkgs, ... }:
let
  sshBookmarks = import ../../data/ssh/bookmarks.nix;
  sshSettings = {
    "*" = sshBookmarks.defaults;
  }
  // lib.mapAttrs (
    _: settings: builtins.removeAttrs settings [ "useOpIdentityAgent" ]
  ) sshBookmarks.hosts;
  sshAgentHosts = lib.attrNames (
    lib.filterAttrs (_: settings: settings.useOpIdentityAgent or false) sshBookmarks.hosts
  );
  sshAgentPath =
    if pkgs.stdenv.hostPlatform.isDarwin then
      ''"~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"''
    else
      "~/.1password/agent.sock";
  sshAgentConfig = lib.concatMapStringsSep "\n" (host: ''
    Match originalhost ${host} exec "test -z $SSH_TTY"
        IdentityAgent ${sshAgentPath}
    Match all'') sshAgentHosts;
in
{
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    settings = sshSettings;
    extraConfig = sshAgentConfig;
  };
}

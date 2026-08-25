{ inputs, ... }:
{
  perSystem =
    { pkgs, ... }:
    let
      mkHome =
        homePkgs:
        inputs.home-manager.lib.homeManagerConfiguration {
          pkgs = homePkgs;
          modules = [
            ../../lib/shell/ssh-bookmarks.nix
            {
              home = {
                username = "ssh-test";
                homeDirectory = "/home/ssh-test";
                stateVersion = "26.11";
              };
            }
          ];
        };

      linux = mkHome pkgs;
      linuxSshConfig =
        pkgs.writeText "ssh-bookmarks-linux-config"
          linux.config.home.file.".ssh/config".text;
      linuxBehavior =
        pkgs.runCommand "ssh-bookmarks-linux-behavior"
          {
            nativeBuildInputs = [
              pkgs.gnugrep
              pkgs.openssh
            ];
          }
          ''
            local_config=$(env -u SSH_TTY ssh -G -F ${linuxSshConfig} ghcny)
            printf '%s\n' "$local_config" | grep -q '^identityagent '

            forwarded_config=$(SSH_TTY=/tmp/forwarded-tty ssh -G -F ${linuxSshConfig} ghcny)
            if printf '%s\n' "$forwarded_config" | grep -q '^identityagent '; then
              printf 'forwarded SSH agent unexpectedly overridden\n' >&2
              exit 1
            fi

            touch "$out"
          '';

      darwinPkgs = import inputs.nixpkgs {
        system = "aarch64-darwin";
        config.allowUnfree = true;
      };
      darwin = mkHome darwinPkgs;
    in
    {
      checks.ssh-bookmarks =
        assert linux.config.programs.ssh.settings.ghcny.data.HostName == "github.com";
        assert
          linux.config.programs.ssh.settings.ghspy.data.IdentityFile == [ "~/.ssh_keys/ghspy-auth.pub" ];
        assert linux.config.programs.ssh.settings.tailacer.data.ForwardAgent;
        assert !(linux.config.programs.ssh.settings.ghcny.data ? useOpIdentityAgent);
        assert pkgs.lib.hasInfix "Match originalhost ghcny exec" linux.config.programs.ssh.extraConfig;
        assert pkgs.lib.hasInfix "IdentityAgent ~/.1password/agent.sock"
          linux.config.programs.ssh.extraConfig;
        assert pkgs.lib.hasInfix
          "IdentityAgent \"~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock\""
          darwin.config.programs.ssh.extraConfig;
        linuxBehavior;
    };
}

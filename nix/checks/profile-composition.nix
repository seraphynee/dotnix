{
  lib,
  inputs,
  self,
  ...
}:
{
  perSystem =
    { pkgs, ... }:
    let
      acerus = self.nixosConfigurations.acerus.config;
      esquire = self.nixosConfigurations.esquire.config;
      workstations = [
        acerus
        esquire
      ];
      workstationHomes = map (config: config.home-manager.users.seraphynee) workstations;
      allWorkstations = predicate: lib.all predicate workstations;
      allWorkstationHomes = predicate: lib.all predicate workstationHomes;
      hasPath = path: config: lib.attrByPath path false config;
      removedInputsAbsent = lib.all (name: !(builtins.hasAttr name inputs)) [
        "catppuccin"
        "flake-aspects"
        "helium"
        "hjem"
        "niri"
        "noctalia-qs"
        "systems"
      ];
    in
    {
      checks.profile-composition =
        assert removedInputsAbsent;
        assert allWorkstations (config: config.programs.mango.enable);
        assert allWorkstationHomes (home: home.programs.noctalia.enable);
        assert allWorkstations (config: config.services.tailscale.enable);
        assert allWorkstations (config: config.networking.networkmanager.enable);
        assert allWorkstations (
          config: lib.elem "multi-user.target" (config.systemd.services.kanata.wantedBy or [ ])
        );
        assert allWorkstations (config: config.services.openssh.enable);
        assert allWorkstations (config: config.virtualisation.incus.enable);
        assert allWorkstationHomes (home: home.programs.fish.enable);
        assert allWorkstationHomes (home: !home.programs.zsh.enable);
        assert allWorkstationHomes (home: home.programs.neovim.enable);
        assert allWorkstationHomes (home: home.programs.atuin.enable);
        assert allWorkstationHomes (home: home.programs.direnv.enable);
        assert allWorkstationHomes (home: home.programs.nh.enable);
        assert allWorkstationHomes (home: home.programs.fzf.enable);
        assert acerus.services.cloudflare-warp.enable;
        assert !(esquire.services.cloudflare-warp.enable or false);
        assert esquire.virtualisation.podman.enable;
        assert !acerus.virtualisation.podman.enable;
        assert hasPath [ "services" "handy" "enable" ] acerus.home-manager.users.seraphynee;
        assert !(hasPath [ "services" "handy" "enable" ] esquire.home-manager.users.seraphynee);
        pkgs.runCommand "profile-composition" { } ''
          touch "$out"
        '';
    };
}

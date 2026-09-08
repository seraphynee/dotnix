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
      vps = self.nixosConfigurations.vps.config;
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
      repositoryRoot = ../..;
      compositionLayoutMatches =
        lib.all (relative: builtins.pathExists (repositoryRoot + relative)) [
          "/modules/profiles/workstation.nix"
          "/modules/profiles/server.nix"
          "/modules/features/development.nix"
          "/modules/features/personal.nix"
        ]
        && !(builtins.pathExists (repositoryRoot + "/modules/profiles.nix"));
    in
    {
      checks.profile-composition =
        assert removedInputsAbsent;
        assert compositionLayoutMatches;
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
        assert vps.i18n.defaultLocale == "en_US.UTF-8";
        assert vps.services.openssh.enable;
        assert allWorkstations (config: config.services.cloudflare-warp.enable);
        assert esquire.virtualisation.podman.enable;
        assert !acerus.virtualisation.podman.enable;
        assert allWorkstationHomes (hasPath [
          "services"
          "handy"
          "enable"
        ]);
        pkgs.runCommand "profile-composition" { } ''
          touch "$out"
        '';
    };
}

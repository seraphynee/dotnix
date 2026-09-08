{ inputs, ... }:
{
  den.aspects.desktop._.noctalia-greeter.nixos =
    { pkgs, ... }:
    {
      imports = [ inputs.noctalia-greeter.nixosModules.default ];

      programs.noctalia-greeter = {
        enable = true;
        settings = {
          cursor = {
            theme = "Bibata-Modern-Ice";
            size = 24;
            path = "${pkgs.bibata-cursors}/share/icons";
          };
          keyboard.layout = "us";
        };
      };

      security.pam.services.greetd.enableGnomeKeyring = true;
    };
}

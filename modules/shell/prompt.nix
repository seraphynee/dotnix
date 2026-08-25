{
  # Fastfetch
  den.aspects.shell._.fastfetch = {
    homeManager = {
      xdg.configFile."fastfetch/config.jsonc".source = ../../dots/config/fastfetch/config.jsonc;
    };
    nixos =
      { pkgs, ... }:
      {
        environment.systemPackages = with pkgs; [ fastfetch ];
      };
    darwin =
      { pkgs, ... }:
      {
        environment.systemPackages = with pkgs; [ fastfetch ];
      };
  };
  # Starship
  den.aspects.shell._.starship.homeManager =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      starshipConfigPath = "${config.xdg.configHome}/starship/starship.toml";
      starshipConfig =
        let
          generatedConfig =
            (pkgs.formats.toml { }).generate "starship-config"
              config.programs.starship.settings;
        in
        pkgs.writeText "starship-config" (
          builtins.replaceStrings [ "format = '''" "$character'''" ] [ "format = \"\"\"" "$character\"\"\"" ]
            (builtins.readFile generatedConfig)
        );
    in
    {
      home.sessionVariables.STARSHIP_CONFIG = starshipConfigPath;

      programs.starship = {
        enable = true;
        enableFishIntegration = true;
        extraPackages = [ pkgs.jj-starship ];
        configPath = starshipConfigPath;
        settings = {
          add_newline = true;

          format = lib.concatStringsSep "\n" [
            "$hostname\\"
            "$directory\\"
            "$custom\\"
            "$git_metrics\\"
            "$git_state\\"
            "$nodejs\\"
            "$bun\\"
            "$nix_shell\\"
            "$fill\\"
            "$line_break\\"
            "$character"
          ];

          character = {
            error_symbol = "[➜](bold red)";
            success_symbol = "[➜](bold green)";
          };

          time = {
            disabled = false;
            format = "[$time]($style) ";
            style = "bold gray";
            time_format = "%T";
            use_12hr = false;
            utc_time_offset = "+7";
          };

          fill.symbol = " ";

          jobs = {
            format = "[$symbol]($style)";
            number_threshold = 1;
            style = "bold red";
            symbol = "";
          };

          git_branch = {
            disabled = true;
            symbol = " ";
          };

          git_status.disabled = true;

          git_state = {
            format = "\\([$state( $progress_current/$progress_total)]($style)\\) ";
            style = "bright-black";
          };

          git_metrics.disabled = false;

          cmd_duration = {
            format = "[$duration]($style)";
            style = "yellow";
          };

          custom.jj = {
            format = "$output ";
            shell = [ "jj-starship" ];
            when = "jj-starship detect";
          };

          package = {
            disabled = true;
            symbol = "󰏗 ";
          };

          aws.symbol = "  ";
          buf.symbol = " ";
          c.symbol = " ";
          conda.symbol = " ";
          crystal.symbol = " ";
          dart.symbol = " ";
          directory.read_only = " 󰌾";
          docker_context.symbol = " ";
          elixir.symbol = " ";
          elm.symbol = " ";
          fennel.symbol = " ";
          fossil_branch.symbol = " ";
          golang.symbol = " ";
          guix_shell.symbol = " ";
          haskell.symbol = " ";
          haxe.symbol = " ";
          hg_branch.symbol = " ";

          hostname = {
            disabled = false;
            format = "[$ssh_symbol](bold blue) on [$hostname](bold red) ";
            ssh_only = true;
            ssh_symbol = "󰣀 ";
          };

          java.symbol = " ";
          julia.symbol = " ";
          kotlin.symbol = " ";
          lua.symbol = " ";
          memory_usage.symbol = "󰍛 ";
          meson.symbol = "󰔷 ";
          nim.symbol = "󰆥 ";
          nix_shell.symbol = " ";
          nodejs.symbol = " ";
          bun.format = "via [🍔 $version](bold green) ";
          ocaml.symbol = " ";

          os.symbols = {
            AlmaLinux = " ";
            Alpaquita = " ";
            Alpine = " ";
            Amazon = " ";
            Android = " ";
            Arch = " ";
            Artix = " ";
            CentOS = " ";
            Debian = " ";
            DragonFly = " ";
            Emscripten = " ";
            EndeavourOS = " ";
            Fedora = " ";
            FreeBSD = " ";
            Garuda = "󰛓 ";
            Gentoo = " ";
            HardenedBSD = "󰞌 ";
            Illumos = "󰈸 ";
            Kali = " ";
            Linux = " ";
            Mabox = " ";
            Macos = " ";
            Manjaro = " ";
            Mariner = " ";
            MidnightBSD = " ";
            Mint = " ";
            NetBSD = " ";
            NixOS = " ";
            OpenBSD = "󰈺 ";
            OracleLinux = "󰌷 ";
            Pop = " ";
            Raspbian = " ";
            RedHatEnterprise = " ";
            Redhat = " ";
            Redox = "󰀘 ";
            RockyLinux = " ";
            SUSE = " ";
            Solus = "󰠳 ";
            Ubuntu = " ";
            Unknown = " ";
            Void = " ";
            Windows = "󰍲 ";
            openSUSE = " ";
          };

          perl.symbol = " ";
          php.symbol = " ";
          pijul_channel.symbol = " ";
          python.symbol = " ";
          rlang.symbol = "󰟔 ";
          ruby.symbol = " ";
          rust.symbol = " ";
          scala.symbol = " ";
          swift.symbol = " ";
          zig.symbol = " ";
        };
      };

      # Starship needs a basic multiline TOML string for backslash continuations.
      home.file."${starshipConfigPath}" = lib.mkForce {
        source = starshipConfig;
      };
    };
}

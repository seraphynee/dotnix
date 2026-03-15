{ __findFile, inputs, ... }:
{
  den.aspects.shell._.packages._ = {
    common = {
      includes = [
        <shell/utils>
      ];

      homeManager =
        { pkgs, ... }:
        {
          home.packages = [ inputs.momoi-say.packages.${pkgs.system}.momoiSay ];
        };
    };

    dev = {
      includes = [ <shell/packages> ];

      homeManager =
        { pkgs, ... }:
        {
          home.packages = with pkgs; [
            # Base tooling
            bat # Cat clone with syntax highlighting
            uutils-coreutils-noprefix # Rust implementation of GNU coreutils
            curl # Data transfer tool for URLs
            wget # File retrieval from web servers
            unzip # Extract ZIP archives
            zip # Create ZIP archives
            p7zip # 7z compression utility
            ffmpeg # Multimedia framework
            mkpasswd # Make password hash
            ouch # Command-line utility for easily compressing and decompressing files and directories
            sesh
            gum

            # Screenshot utility
            grim
            swappy
            slurp

            wf-recorder # for screen recording

            # Disk Usage Analyzers
            dua # Disk usage analyzer with TUI
            gdu # Fast disk usage analyzer
            dust # More intuitive du replacement

            # Process & System Monitoring
            procs # Modern process viewer (ps alternative)
            gping # ping, but with graph

            # File Searching
            fd # User-friendly find alternative
            ripgrep # Ultra-fast grep alternative
            skim # fuzzy-finder alternative to fzf

            # Keys
            age
            age-plugin-yubikey
            yubikey-manager # optional but handy (ykman)
            yubico-piv-tool # optional but handy (PIV debugging)
            pcsclite
            ssh-to-age

            # Development Tools
            hyperfine # Command-line benchmarking tool
            just # Command runner (make alternative)
            devenv # Reproducible development environments
            devbox # Development environment manager
            watchexec # Run commands when files change
            entr # Run commands when files change
            epy # Simple Python package manager
            zlib # Compression library

            # Typescript
            nodejs # JavaScript runtime
            bun # JavaScript runtime & toolkit
            pnpm # Fast JavaScript package manager
            biome # JavaScript and Typescript lsp

            # Golang
            go # Go programming language
            gopls # Go lsp

            #Rust
            cargo # Rust package manager
            rustc # Rust compiler

            #Zig
            zig # Zig programming language
            zls # Zig lsp

            # Haskell
            stack # Haskell build tool
            cabal-install # Haskell package manager
            # ghc # Glasgow Haskell Compiler
            hpack # Haskell package manager
            # haskell-language-server # Haskell language server
            ghciwatch # GHCi file watcher

            # Lua
            lua
            stylua # Lua formatter
            lua-language-server # Lua language server

            # C C++
            gcc # GNU Compiler Collection
            gnumake # GNU Make
            clang-tools # Clang tools

            # Python
            uv # Python package manager
            ruff # Python linter & formatter
            basedpyright # Python lsp
            pipx
            python315

            # Editors
            # neovim
            # zed-editor

            # Android Development
            scrcpy # Android device mirroring
            android-tools # Android platform tools

            # Cosmetics
            cmatrix
          ];
        };
    };

    personal = { };
  };
}

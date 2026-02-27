default:
    @just --list

# Quality
fmt-lint:
    nix fmt

treefmt-check:
    nix fmt -- --ci

check:
    nix flake check --print-build-logs

secrets-scan:
    nix run nixpkgs#gitleaks -- detect --source . --verbose

ci-check:
    just treefmt-check
    just check

# Daily workflow
up:
    nix flake update

upp target:
    nix flake update {{ target }}

write-flake:
    nix run .#write-flake

repl:
    nh os repl

hooks-install:
    lefthook install

clean:
    sudo nix-collect-garbage -d

# Host operations
rebuild host:
    if [ "$(uname -s)" = "Darwin" ]; then nh darwin switch . -H {{ host }}; else nh os switch . -H {{ host }}; fi

rebuild-boot host:
    sudo nixos-rebuild boot --flake .#{{ host }}

# Remote/bootstrap
anywhere host target:
    nix run github:nix-community/nixos-anywhere -- --flake {{ host }} --host-target {{ target }}

disko-mount-only host flake='.':
    sudo nix --extra-experimental-features "nix-command flakes" run github:nix-community/disko/latest -- --mode destroy,format,mount --flake '{{ flake }}#{{ host }}'

disko-install host disk target flake='.':
    sudo nix --extra-experimental-features "nix-command flakes" run 'github:nix-community/disko/latest#disko-install' -- --flake '{{ flake }}#{{ host }}' --disk {{ disk }} {{ target }}

disko-install-remount host flake='.' rw_store_size='20G':
    sudo nix --extra-experimental-features "nix-command flakes" run github:nix-community/disko/latest -- --mode destroy,format,mount --flake '{{ flake }}#{{ host }}'
    sudo mount -o remount,size={{ rw_store_size }},noatime /nix/.rw-store
    sudo nixos-install --flake '{{ flake }}#{{ host }}'

install-after-key host flake='.' rw_store_size='20G':
    sudo mount -o remount,size={{ rw_store_size }},noatime /nix/.rw-store
    sudo nixos-install --flake '{{ flake }}#{{ host }}'

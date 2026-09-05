{ inputs, ... }:
{
  imports = [
    # Avoid flake-file's legacy `flake.modules` output, which triggers
    # `unknown flake output 'modules'` on recent Nix versions.
    (inputs.flake-file.flakeModules.default or { })
    (inputs.den.flakeModules.dendritic or { })
  ];

  # other inputs may be defined at a module using them.
  flake-file.outputs = ''
    inputs: inputs.flake-parts.lib.mkFlake { inherit inputs; } (inputs.import-tree [
      ./nix
      ./modules
    ])
  '';

  flake-file.nixConfig = {
    extra-substituters = [
      "https://cache.numtide.com"
      "https://handy-computer.cachix.org"
    ];
    extra-trusted-public-keys = [
      "niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g="
      "handy-computer.cachix.org-1:Sihzctn6DC0CJM5QeL+9nBEL3CL8c33m777C+eIv748="
    ];
  };
}

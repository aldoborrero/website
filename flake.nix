{
  description = "My Personal Website";

  nixConfig = {
    extra-substituters = [
      "https://cache.nixos.org"
      "https://nix-community.cachix.org"
    ];
    extra-trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    ];
  };

  inputs = {
    # packages
    nixpkgs.url = github:nixos/nixpkgs/nixpkgs-unstable;

    # utilities
    flake-utils.url = github:numtide/flake-utils;
    devshell = {
      url = github:numtide/devshell;
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-utils.follows = "flake-utils";
    };
  };

  outputs = {
    self,
    devshell,
    flake-utils,
    nixpkgs,
    ...
  } @ inputs: let
    inherit (flake-utils.lib) eachDefaultSystem;
  in
    eachDefaultSystem
    (system: let
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
        overlays = [
          devshell.overlay
          (import ./.nix/overlays.nix)
        ];
      };

      linters = with pkgs; [
        alejandra # https://github.com/kamadorueda/alejandra
        hadolint # https://github.com/hadolint/hadolint
        nodePackages.prettier # https://prettier.io/
        shellcheck # https://github.com/koalaman/shellcheck
        shfmt # https://github.com/mvdan/sh
        tfsec # https://github.com/aquasecurity/tfsec
        treefmt # https://github.com/numtide/treefmt
      ];
    in {
      # nix develop
      devShells.default = import ./devshell.nix {inherit inputs pkgs linters;};

      # nix flake check
      checks = import ./checks.nix {inherit self pkgs linters;};
    });
}

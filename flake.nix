{
  description = "My Personal Website";

  nixConfig = {
    extra-substituters = [
      "https://nix-community.cachix.org"
    ];
    extra-trusted-public-keys = [
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    ];
  };

  inputs = {
    # packages
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    nixpkgs-tf.url = "github:nixos/nixpkgs/4ab8a3de296914f3b631121e9ce3884f1d34e1e5";

    # flake-parts
    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };
    flake-root.url = "github:srid/flake-root";

    # utilities
    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    devshell = {
      url = "github:numtide/devshell";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    haumea = {
      url = "github:nix-community/haumea/v0.2.2";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    lib-extras = {
      url = "github:aldoborrero/lib-extras";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs @ {
    self,
    flake-parts,
    haumea,
    nixpkgs,
    ...
  }: let
    lib = nixpkgs.lib.extend (l: _: (inputs.lib-extras.lib l));
    localInputs = haumea.lib.load {
      src = ./.;
      loader = haumea.lib.loaders.path;
    };
  in
    flake-parts.lib.mkFlake
    {
      inherit inputs;
      specialArgs = {inherit lib localInputs;};
    }
    {
      imports = [
        inputs.devshell.flakeModule
        inputs.flake-parts.flakeModules.easyOverlay
        inputs.flake-root.flakeModule
        inputs.treefmt-nix.flakeModule
      ];

      debug = false;

      systems = ["x86_64-linux"];

      perSystem = {
        pkgs,
        pkgs-tf,
        lib,
        config,
        system,
        self',
        ...
      }: {
        # nixpkgs
        _module.args = {
          pkgs = lib.nix.mkNixpkgs {
            inherit system;
            inherit (inputs) nixpkgs;
          };
          pkgs-tf = lib.nix.mkNixpkgs {
            inherit system;
            nixpkgs = inputs.nixpkgs-tf;
          };
        };

        # packages
        packages = {
          # jeez hashicorp ... (for now until OpenTOFU get's ready)
          tf-custom = pkgs-tf.terraform.withPlugins (p: [
            p.cloudflare
            p.external
            p.local
            p.null
            p.secret
            p.time
            p.tls
          ]);

          mdformat-custom = pkgs.python3Packages.mdformat.withPlugins (with pkgs.python3Packages; [
            mdformat-beautysh
            mdformat-footnote
            mdformat-frontmatter
            mdformat-gfm
            mdformat-nix-alejandra
            mdformat-simple-breaks
          ]);
        };

        # devshells
        devshells.default = {
          name = "website";
          packages = with pkgs; [
            alejandra # used by mdformat-nix-alejandra
            age-plugin-yubikey
            hugo
            rage
            self'.packages.tf-custom
            sops
            ssh-to-age
          ];
          commands = [
            {
              name = "hugo-server";
              category = "hugo";
              help = "Runs hugo server in development mode";
              command = "hugo server --source $PRJ_ROOT/website";
            }
            {
              name = "sops-update-keys";
              category = "sops";
              help = "Re-encrypt secrets with sops";
              command = "sops updatekeys --yes $PRJ_ROOT/secrets/secrets.yaml";
            }
            {
              name = "fmt";
              category = "nix";
              help = "Format the source tree";
              command = ''nix fmt'';
            }
            {
              name = "check";
              category = "nix";
              help = "Check the source tree";
              command = ''nix flake check'';
            }
          ];
        };

        # treefmt
        treefmt.config = {
          inherit (config.flake-root) projectRootFile;
          flakeFormatter = true;
          flakeCheck = true;
          programs = {
            alejandra.enable = true;
            deadnix.enable = true;
            mdformat.enable = true;
            deno.enable = true;
            shfmt.enable = true;
            terraform.enable = true;
          };
          settings.formatter = {
            deno.excludes = ["*.md"];
            mdformat.package = self'.packages.mdformat-custom;
          };
        };

        # checks
        checks = {
          tfsec =
            pkgs.runCommand "tfsec" {
              nativeBuildInputs = with pkgs; [tfsec];
            } ''
              # keep timestamps
              cp --no-preserve=mode --preserve=timestamps -r ${self} source
              cd source
              HOME=$TMPDIR tfsec --concise-output terraform
              touch $out
            '';
        };
      };
    };
}

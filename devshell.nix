{
  inputs,
  pkgs,
  linters,
}: let
  inherit (pkgs.devshell) mkShell;

  agenix = inputs.agenix.defaultPackage.${pkgs.system};
  nixos-generate = inputs.nixos-generators.defaultPackage.${pkgs.system};

  # devshell command categories
  pkgWithCategory = category: package: {inherit package category;};
  dev = pkgWithCategory "dev";
  devops = pkgWithCategory "devops";
  formatter = pkgWithCategory "formatters";
  utils = pkgWithCategory "utils";
in
  mkShell {
    name = "website";
    motd = "";
    packages = with pkgs;
      [
        # dev tools
        docker-compose
        hugo

        # devops tools
        awscli2
        terragrunt
        tf-custom
        tfsec

        # utils
        age
        just
        sops
        treefmt
      ]
      ++ linters;

    commands = with pkgs; [
      # dev tools
      (dev docker-compose)
      (dev hugo)

      # devops tools
      (devops awscli2)
      (devops terragrunt)
      (devops tf-custom // {name = "terraform";})
      (devops tfsec)

      # utils
      (utils age)
      (utils just)
      (utils sops)
      (utils treefmt)
    ];
  }

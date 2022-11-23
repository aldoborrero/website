{
  inputs,
  pkgs,
  linters,
}: let
  inherit (pkgs.devshell) mkShell;

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
        hugo

        # devops tools
        terragrunt
        tf-custom
        tfsec

        # utils
        just
        sops
        treefmt
      ]
      ++ linters;

    commands = with pkgs; [
      # dev tools
      (dev hugo)

      # devops tools
      (devops terragrunt)
      (devops tf-custom // {name = "terraform";})
      (devops tfsec)

      # utils
      (utils just)
      (utils sops)
      (utils treefmt)
    ];
  }

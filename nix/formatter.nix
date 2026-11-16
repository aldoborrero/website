{
  flake,
  inputs,
  pkgs,
  ...
}:
let
  mod = inputs.treefmt-nix.lib.evalModule pkgs {
    projectRootFile = "flake.nix";

    programs = {
      # nix: deadnix strips dead code, then nixfmt formats
      deadnix = {
        enable = true;
        no-lambda-pattern-names = true;
        priority = 1;
      };
      nixfmt = {
        enable = true;
        priority = 2;
      };

      # shell
      shellcheck = {
        enable = true;
        includes = [
          "*.sh"
          "*.bash"
          "*.envrc"
          "*.envrc.*"
        ];
        priority = 1;
      };
      shfmt = {
        enable = true;
        includes = [
          "*.sh"
          "*.bash"
          "*.envrc"
          "*.envrc.*"
        ];
        priority = 2;
      };

      # infrastructure
      terraform = {
        enable = true;
        package = pkgs.opentofu;
      };

      # data / config
      yamlfmt = {
        enable = true;
        settings.formatter = {
          type = "basic";
          indent = 2;
          retain_line_breaks = true;
        };
      };
      jsonfmt.enable = true;
      taplo.enable = true;
      just.enable = true;

      # markdown (blog posts): rumdl lints with autofix, then formats.
      # Rules are configured in .rumdl.toml.
      rumdl-check = {
        enable = true;
        excludes = [ "website/archetypes/**" ];
        priority = 1;
      };
      rumdl-format = {
        enable = true;
        excludes = [ "website/archetypes/**" ];
        priority = 2;
      };
    };

    settings = {
      on-unmatched = "debug";
      excludes = [
        # sops-encrypted: reformatting would invalidate the MAC
        "secrets/**"
        # hugo-generated assets
        "website/resources/_gen/**"
        ".claude/**"
        ".agents/**"
      ];
    };
  };

  wrapper = mod.config.build.wrapper;
in
wrapper
// {
  passthru = wrapper.passthru // {
    tests.check = mod.config.build.check flake;
  };
}

# The blog, built by Hugo in the Nix sandbox: `nix build .#site`.
{ pkgs, ... }:
pkgs.callPackage ./package.nix { }

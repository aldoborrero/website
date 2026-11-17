{ pkgs, perSystem }:
pkgs.mkShellNoCC {
  packages = with pkgs; [
    just
    perSystem.self.formatter

    # site: `just serve` runs hugo directly; builds go through `nix build .#site`
    hugo
    pagefind # the search index: `just search` serves a drafts build with one
    lychee # link checker: `just check-links` (external), checks/links.nix (internal)

    # infrastructure: Cloudflare Worker + domain (terraform/), deploys (wrangler)
    perSystem.self.tofu
    wrangler # uploads and deploys Worker versions (wrangler.jsonc)

    # secrets: sops-encrypted env for the tofu providers, decrypted with a YubiKey
    sops
    age
    age-plugin-yubikey
    ssh-to-age
  ];

  env.NIX_PATH = "nixpkgs=${toString pkgs.path}";

  shellHook = ''
    export PRJ_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
    export NIX_DIR="$PRJ_ROOT/nix"

    # Keep the hugo cache in the project rather than $HOME.
    export HUGO_CACHEDIR="$PRJ_ROOT/.cache/hugo"
  '';
}

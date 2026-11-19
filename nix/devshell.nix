{ pkgs, perSystem }:
pkgs.mkShellNoCC {
  packages = with pkgs; [
    just
    perSystem.self.formatter

    # site: hugo resolves its theme as a Go module, so it needs go + git
    hugo
    go
    git

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

    # Keep the toolchain caches in the project rather than $HOME.
    # GOMODCACHE is set explicitly: a global one would otherwise win over GOPATH.
    export GOPATH="$PRJ_ROOT/.go"
    export GOMODCACHE="$GOPATH/pkg/mod"
    export HUGO_CACHEDIR="$PRJ_ROOT/.cache/hugo"
  '';
}

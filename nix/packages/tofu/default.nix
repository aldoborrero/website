# OpenTofu with the providers used under terraform/ baked in, so `tofu init`
# never downloads plugins and the provider versions follow flake.lock.
{ pkgs, ... }:
pkgs.opentofu.withPlugins (p: [ p.cloudflare_cloudflare ])

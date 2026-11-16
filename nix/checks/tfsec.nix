# Static security scan of the Cloudflare infrastructure under terraform/.
{ flake, pkgs, ... }:
pkgs.runCommand "tfsec" { nativeBuildInputs = [ pkgs.tfsec ]; } ''
  HOME=$TMPDIR tfsec --concise-output --no-color ${flake}/terraform
  touch $out
''

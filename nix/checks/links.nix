# Internal links and anchors of the published site, checked offline: every
# link to a page, file or #fragment of the site must resolve inside the
# build. Root-relative links resolve against the site (--root-dir), absolute
# ones to https://aldoborrero.com/ are remapped onto it, directory links need
# their index.html. External links are not checked here (no network in the
# sandbox): `just check-links` and .github/workflows/links.yml do that.
{ pkgs, perSystem, ... }:
pkgs.runCommand "links"
  {
    nativeBuildInputs = [ pkgs.lychee ];
    site = perSystem.self.site;
  }
  ''
    export HOME=$TMPDIR
    # lychee builds its HTTP client even offline, and that needs CA certs.
    export SSL_CERT_FILE=${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt
    lychee --offline --no-progress --format compact \
      --root-dir "$site" \
      --remap "https://aldoborrero\.com/(.*) file://$site/\$1" \
      --index-files index.html \
      --include-fragments \
      "$site/**/*.html"
    touch $out
  ''

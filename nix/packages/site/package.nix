# aldoborrero.com, built hermetically: the only inputs are hugo, the theme in
# website/ and self-hosted fonts. Nothing is fetched at build time, and
# --panicOnWarning turns Hugo deprecations into build failures, so a nixpkgs
# bump that breaks a template fails `nix flake check` instead of production.
{
  lib,
  stdenvNoCC,
  fetchurl,
  hugo,
  python3Packages,
  hanken-grotesk,
  ibm-plex,
}:
let
  # Newsreader is not packaged in nixpkgs on its own. Pin the variable fonts to
  # the google/fonts revision that nixpkgs' google-fonts uses, instead of
  # pulling the whole google-fonts source.
  googleFontsRev = "5174b3333331c966c38f4355d50b03ca1c1df2f9";
  newsreader = {
    roman = fetchurl {
      name = "newsreader-roman.ttf";
      url = "https://raw.githubusercontent.com/google/fonts/${googleFontsRev}/ofl/newsreader/Newsreader%5Bopsz,wght%5D.ttf";
      hash = "sha256-igjRP4psDVG+N5pgr4T5RfZTaaZ+UJ7jw73MQhJU18E=";
    };
    italic = fetchurl {
      name = "newsreader-italic.ttf";
      url = "https://raw.githubusercontent.com/google/fonts/${googleFontsRev}/ofl/newsreader/Newsreader-Italic%5Bopsz,wght%5D.ttf";
      hash = "sha256-eWZoYR+Atk1a3xgv3jtvKe2DtOfL7HuWk36ErAE2R5I=";
    };
  };
  plexMono = (ibm-plex.override { families = [ "mono-variable" ]; }).mono-variable.webfont;

  # Basic Latin, Latin-1, Latin Extended-A, typographic punctuation, arrows.
  unicodes = "U+0000-00FF,U+0100-017F,U+0131,U+0152-0153,U+02BB-02BC,U+02C6,U+02DA,U+02DC,U+2000-206F,U+20AC,U+2122,U+2190-2193,U+2212,U+2215,U+FEFF,U+FFFD";

  # Variable woff2 files subset to Latin, served from /fonts/.
  fonts = stdenvNoCC.mkDerivation {
    pname = "aldoborrero-site-fonts";
    version = "1";
    dontUnpack = true;
    nativeBuildInputs = [
      python3Packages.fonttools
      python3Packages.brotli
    ];
    buildPhase = ''
      runHook preBuild
      subset() {
        pyftsubset "$1" --output-file="$out/$2.woff2" --flavor=woff2 \
          --unicodes='${unicodes}' --layout-features='*' --no-hinting --desubroutinize
      }
      mkdir -p $out
      subset ${newsreader.roman} newsreader-roman
      subset ${newsreader.italic} newsreader-italic
      subset '${hanken-grotesk}/share/fonts/variable/HankenGrotesk[wght].ttf' hanken-grotesk
      subset '${plexMono}/share/fonts/woff2/IBM Plex Mono Var-Roman.woff2' plex-mono
      runHook postBuild
    '';
    dontInstall = true;
    meta.license = lib.licenses.ofl;
  };
in
stdenvNoCC.mkDerivation {
  pname = "aldoborrero-site";
  version = "0";

  src = lib.fileset.toSource {
    root = ../../../website;
    fileset = lib.fileset.difference ../../../website (
      lib.fileset.maybeMissing ../../../website/public
    );
  };

  nativeBuildInputs = [ hugo ];

  buildPhase = ''
    runHook preBuild
    mkdir -p static/fonts
    cp ${fonts}/*.woff2 static/fonts/
    hugo --minify --panicOnWarning --destination $out
    runHook postBuild
  '';
  dontInstall = true;
  dontFixup = true;

  passthru = { inherit fonts; };

  meta = {
    description = "aldoborrero.com, the static site served from the Cloudflare Worker";
    platforms = lib.platforms.all;
  };
}

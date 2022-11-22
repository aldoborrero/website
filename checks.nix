{
  self,
  linters,
  pkgs,
}: {
  format =
    pkgs.runCommand "treefmt" {
      nativeBuildInputs = linters;
    } ''
      # keep timestamps so that treefmt is able to detect mtime changes
      cp --no-preserve=mode --preserve=timestamps -r ${self} source
      cd source
      HOME=$TMPDIR treefmt --fail-on-change
      touch $out
    '';
  tfsec =
    pkgs.runCommand "tfsec" {
      nativeBuildInputs = linters;
    } ''
      # keep timestamps so that treefmt is able to detect mtime changes
      cp --no-preserve=mode --preserve=timestamps -r ${self} source
      cd source
      HOME=$TMPDIR tfsec --concise-output terraform
      touch $out
    '';
}

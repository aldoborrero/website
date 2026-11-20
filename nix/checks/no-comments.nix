# No HTML comment from content in the published site. Drafts end with notes
# for the author in <!-- … -->; website/layouts/_partials/content.html strips
# them, and this fails the build if one still gets through:
#   - pages and the feed stylesheet: `<!--` (the minifier also drops the
#     theme's own comments, so there are no legitimate ones to allow; a
#     comment shown as code is `&lt;!--` and passes);
#   - feeds: entry HTML is escaped, so a comment shows as `&lt;!--` (a
#     comment shown as code is escaped twice, `&amp;lt;!--`, and passes).
# The search index needs no check of its own: Pagefind indexes the visible
# text of the pages above and never the comments in them.
{ pkgs, perSystem, ... }:
pkgs.runCommand "no-comments"
  {
    nativeBuildInputs = [ pkgs.ripgrep ];
    site = perSystem.self.site;
  }
  ''
    found=0
    if rg --no-heading -o '.{0,60}<!--.{0,60}' -g '*.{html,xsl,json,txt}' "$site"; then
      found=1
    fi
    if rg --no-heading -o '.{0,60}(<!--|&lt;!--).{0,60}' -g '*.xml' "$site"; then
      found=1
    fi
    if [ "$found" = 1 ]; then
      echo "HTML comments reach the published site (above); see website/layouts/_partials/content.html"
      exit 1
    fi
    touch $out
  ''

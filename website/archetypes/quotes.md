---
# A quotation with its source; the page is called "A quote from <source>".
# The body below the front matter (optional) is your short comment.
# Leave the title empty: rumdl wants the key, the page builds the title.
title: ""
slug: "{{ .File.ContentBaseName | replaceRE `^\d{4}-\d{2}-\d{2}-` "" }}"
date: {{ .Date }}
{{- with site.Params.newlang }}
# Language of this entry (`just new … --lang es`); en when the key is absent.
lang: {{ . }}
{{- end }}
quote: |
  
source: ""
sourceUrl: ""
# Optional: where it was said, e.g. "on Mastodon" or "in Nix Pills, chapter 8".
context: ""
# Thumbnail in lists (posts only) and share image: a file in the page bundle
# or a /images/... path; the build fails if it does not exist.
# image: ""
# Describes the image for the share preview (og:image:alt).
# imageAlt: ""
tags: []
draft: true
---

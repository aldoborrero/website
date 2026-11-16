---
# A quotation with its source; the page is called "A quote from <source>".
# The body below the front matter (optional) is your short comment.
# Leave the title empty: rumdl wants the key, the page builds the title.
title: ""
slug: "{{ .File.ContentBaseName | replaceRE `^\d{4}-\d{2}-\d{2}-` "" }}"
date: {{ .Date }}
quote: |
  
source: ""
sourceUrl: ""
# Optional: where it was said, e.g. "on Mastodon" or "in Nix Pills, chapter 8".
context: ""
tags: []
draft: true
---

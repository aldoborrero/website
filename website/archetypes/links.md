---
# Someone else's work plus commentary. The title is the linked page's title;
# the heading links out, the permalink stays here.
title: ""
slug: "{{ .File.ContentBaseName | replaceRE `^\d{4}-\d{2}-\d{2}-` "" }}"
date: {{ .Date }}
{{- with site.Params.newlang }}
# Language of this entry (`just new … --lang es`); en when the key is absent.
lang: {{ . }}
{{- end }}
link: ""
# Who made it: credit by name whenever it is known.
by: ""
# Optional: where you found it.
via: ""
viaUrl: ""
tags: []
draft: true
---

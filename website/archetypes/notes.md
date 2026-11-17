---
# A short thought, a few paragraphs. The title is optional: leave it empty
# and the page is called "Note, <date>".
title: ""
slug: "{{ .File.ContentBaseName | replaceRE `^\d{4}-\d{2}-\d{2}-` "" }}"
date: {{ .Date }}
{{- with site.Params.newlang }}
# Language of this entry (`just new … --lang es`); en when the key is absent.
lang: {{ . }}
{{- end }}
tags: []
draft: true
---

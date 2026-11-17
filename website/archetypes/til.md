---
# Today I learned: one problem, solved. The first sentence states the fact.
title: "{{ .File.ContentBaseName | replaceRE `^\d{4}-\d{2}-\d{2}-` "" | humanize }}"
slug: "{{ .File.ContentBaseName | replaceRE `^\d{4}-\d{2}-\d{2}-` "" }}"
date: {{ .Date }}
{{- with site.Params.newlang }}
# Language of this entry (`just new … --lang es`); en when the key is absent.
lang: {{ . }}
{{- end }}
# Groups the TIL on /til/ (lowercase, e.g. nix, git, cloudflare).
topic: ""
tags: []
draft: true
---

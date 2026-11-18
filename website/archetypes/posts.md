---
title: "{{ .File.ContentBaseName | replaceRE `^\d{4}-\d{2}-\d{2}-` "" | humanize }}"
slug: "{{ .File.ContentBaseName | replaceRE `^\d{4}-\d{2}-\d{2}-` "" }}"
date: {{ .Date }}
{{- with site.Params.newlang }}
# Language of this entry (`just new … --lang es`); en when the key is absent.
lang: {{ . }}
{{- end }}
description: ""
# Thumbnail in lists (posts only) and share image: a file in the page bundle
# or a /images/... path; the build fails if it does not exist.
# image: ""
# Describes the image for the share preview (og:image:alt).
# imageAlt: ""
tags: []
draft: true
---

---
# A short thought, a few paragraphs. The title is optional: leave it empty
# and the page is called "Note, <date>".
title: ""
slug: "{{ .File.ContentBaseName | replaceRE `^\d{4}-\d{2}-\d{2}-` "" }}"
date: {{ .Date }}
tags: []
draft: true
---

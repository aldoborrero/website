---
title: "{{ .File.ContentBaseName | replaceRE `^\d{4}-\d{2}-\d{2}-` "" | humanize }}"
slug: "{{ .File.ContentBaseName | replaceRE `^\d{4}-\d{2}-\d{2}-` "" }}"
date: {{ .Date }}
description: ""
tags: []
draft: true
---

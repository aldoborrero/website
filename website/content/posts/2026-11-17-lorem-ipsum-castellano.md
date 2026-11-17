---
# Sample entry: draft, lorem ipsum in Spanish. Shows what the theme writes
# in a Spanish entry (dates, reading time, contents, callout titles, copy
# button, anchors). Delete once real Spanish posts exist.
title: "Lorem ipsum en castellano: «comillas», fechas y avisos"
slug: lorem-ipsum-castellano
date: 2026-11-17T12:00:00Z
lastmod: 2026-11-19T09:00:00Z
lang: es
draft: true
description: "Un borrador de prueba para las entradas en castellano: fechas, índice, avisos y bloques de código."
tags: [lorem]
---

Lorem ipsum dolor sit amet, «consectetur adipiscing» elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua, con una nota al pie[^1] y otra más[^2].

## Avisos

> [!NOTE]
> Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat.

> [!TIP]
> Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore.

> [!WARNING]
> Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.

> [!CAUTION] Un título propio
> Curabitur pretium tincidunt lacus, nulla gravida orci a odio.

## Código

Electroencefalografista, desoxirribonucleico y otras palabras largas para ver la división silábica en pantallas estrechas: anticonstitucionalmente.

```nix {file="flake.nix" hl_lines=[2]}
{
  description = "Lorem ipsum";
  outputs = { self, nixpkgs }: { };
}
```

### Un apartado menor

```console
$ nix flake check
```

[^1]: Lorem ipsum dolor sit amet, consectetur adipiscing elit.
[^2]: Sed do eiusmod tempor incididunt ut labore, con [un enlace](https://example.org/).

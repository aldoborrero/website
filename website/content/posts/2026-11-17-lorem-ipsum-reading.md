---
title: "Lorem ipsum: callouts, code and anchors"
slug: lorem-ipsum-reading
date: 2026-11-17T12:00:00Z
draft: true
description: "A draft sample for callouts, code blocks with file names and highlighted lines, and heading anchors."
tags: [lorem]
series: Lorem ipsum, the series
seriesOrder: 2
# Sample toot URL (not a real toot): shows the replies block.
mastodon: https://fosstodon.org/@aldo/100000000000000001
---

Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.

## Callouts

> [!NOTE]
> Lorem ipsum dolor sit amet, with [a link to example.org](https://example.org/) and `inline code`.

> [!TIP]
> Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris.

> [!IMPORTANT]
> Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore.

> [!WARNING]
> Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia.

> [!CAUTION]
> Sed ut perspiciatis unde omnis iste natus error sit voluptatem accusantium.

> [!NOTE] A title of your own
> Nemo enim ipsam voluptatem quia voluptas sit aspernatur aut odit aut fugit.
{source="Lorem, *Ipsum Quarterly*" url="<https://example.org/lorem>"}

A plain quote keeps its own style:

> Neque porro quisquam est, qui dolorem ipsum quia dolor sit amet.
{source="Cicero, *De finibus*"}

## Code

A block with a file name and two highlighted lines:

```nix {file="flake.nix" hl_lines=[3,4]}
{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  outputs = { self, nixpkgs }: {
    packages.x86_64-linux.default = nixpkgs.legacyPackages.x86_64-linux.hello;
  };
}
```

A shell session (the prompt is not copied):

```console
$ nix build .#site
$ ls result-site
```

No language at all:

```text
plain text, lorem ipsum
```

### A third-level heading

Ut enim ad minima veniam, quis nostrum exercitationem ullam corporis suscipit laboriosam.

1. In a list:

   ```sh
   nix profile install github:aldoborrero/lorem-ipsum-a-very-long-url-that-should-wrap/gh-pages/main
   ```

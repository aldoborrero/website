---
# Sample entry: draft, lorem ipsum, to try sidenotes, attributed quotes and
# captions with links (GOAL-6).
title: "Lorem ipsum with notes and quotes"
slug: lorem-ipsum-notes
date: 2026-11-17T12:00:00+01:00
description: "Footnotes that sit in the margin on wide screens, a quotation with its source, and a caption with a link."
tags: [lorem]
draft: true
---

Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.[^short] Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat.

Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur.[^link] Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.

## A quotation with its source

Sed ut perspiciatis unde omnis iste natus error sit voluptatem accusantium doloremque laudantium. Its author wrote:

> Nemo enim ipsam voluptatem quia voluptas sit aspernatur aut odit aut fugit, sed quia consequuntur magni dolores eos qui ratione voluptatem sequi nesciunt.
{source="Marcus Tullius Cicero, *De finibus bonorum et malorum*" url="<https://en.wikipedia.org/wiki/De_finibus_bonorum_et_malorum>"}

A quotation without a source stays a plain blockquote:

> Neque porro quisquam est, qui dolorem ipsum quia dolor sit amet, consectetur, adipisci velit.

## A list, a long note and a caption with a link

- Ut enim ad minima veniam, quis nostrum exercitationem.[^long]
- Quis autem vel eum iure reprehenderit qui in ea voluptate velit esse.
- At vero eos et accusamus et iusto odio dignissimos ducimus.

![A chart: the difficulty of Nix over time](/images/posts/using-effectively-the-nix-repl/difficulty-of-nix.jpeg "A caption with a link to the [Blender Foundation's open movies](https://studio.blender.org/films/), rendered from the image title.")

Nam libero tempore, cum soluta nobis est eligendi optio cumque nihil impedit quo minus id quod maxime placeat facere possimus.[^block] Omnis voluptas assumenda est, omnis dolor repellendus.

[^short]: A short note in the margin.
[^link]: A note with [a link](https://gohugo.io/) and `some code`.
[^long]: A longer note. Temporibus autem quibusdam et aut officiis debitis aut rerum necessitatibus saepe eveniet ut et voluptates repudiandae sint et molestiae non recusandae. Itaque earum rerum hic tenetur a sapiente delectus.
[^block]: A note with two paragraphs.

    The second paragraph of the note.

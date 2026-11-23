# Design critique: the post page, judged on the Jellyfin Kids article

November 2026 (GOAL-6). Target: `website/layouts/posts/page.html` and what it shares with the rest of the site (`baseof.html`, the render hooks, `theme.css`), rendered on "A YouTube Kids for your Jellyfin server" (branch `content/from-ccq`, built locally, not committed here). Mode: **Read**. The longform direction, the Medianoche tokens and light-by-default were fixed and not reviewed.

Method: Impeccable `critique`, run with two independent assessments: a design review (A) and the detector plus browser measurements (B). Both were measured in Chromium at 1440×900 and 390×844, light and dark.

## Verdict

**Specific in the column, generic in the frame.**

The reading column is the strong part:

- Newsreader at 20px/1.65 with about 74 characters per line on desktop, and 18px with about 49 at 390px.
- Ink on ground is 15.2:1.
- h2 has 48px above and 16px below, so headings attach to their section.
- The date and reading time sit in a margin rail that lines up with the title.

The frame commits little: a wordmark, a nav, and an accent used only on links and rules. That is acceptable for Read. The margin system is the signature move, and it was underused: it showed nothing but the date and a static contents list.

Heuristics (A): 23/32. Two were scored n/a (error recovery, help). That is 72%, **Good**.

| # | Heuristic | Score | Key issue |
| --- | --- | --- | --- |
| 1 | Visibility of system status | 2 | Sticky contents list never shows the current section |
| 2 | Match with the real world | 4 | Conventional article order and labels |
| 3 | User control and freedom | 3 | No way back to Contents on mobile except scrolling up |
| 4 | Consistency and standards | 3 | Block code smaller than inline code; two blockquote styles |
| 5 | Error prevention | 2 | The URL readers must copy was clipped behind a scrollbar |
| 6 | Recognition rather than recall | 3 | Contents, tags and follow links labelled and visible |
| 7 | Flexibility and efficiency | 3 | Theme toggle, feeds, contents, zoom; no copy button on code |
| 8 | Aesthetic and minimalist design | 3 | Calm column; the end of the post repeats links |
| 9 | Error recovery | n/a | Static page |
| 10 | Help and documentation | n/a | The article is the documentation |

## Strengths

1. **Measure and rhythm:** 74 characters per line, 1.65 leading, and a 3:1 space ratio above and below headings.
2. **Contrast in both themes:** the lowest text contrast on the page is 5.32:1 (mobile contents links). Muted text is 5.94:1 in light and 6.6:1 in dark.
3. **The margin column as a metadata rail:** on mobile it collapses into a meta row and a `<details>` contents list.

## Issues, ranked by impact on reading

| # | Sev | Issue | Done |
| --- | --- | --- | --- |
| 1 | P1 | **Code inside a list was clipped and misaligned.** The plugin-repository URL in "Try it at home" (the one string readers must copy) was cut at `…/gh-pages/ma` behind a scrollbar at both widths. On mobile the block bled to the right edge only, half outside the list indent. | Code inside a list item now wraps (`pre-wrap`), and on mobile it keeps the item's indent with the 2px left rule. |
| 2 | P1 | **Block code was smaller than inline code:** 13.1px blocks against 16px inline. Commands were the hardest text to read. | Blocks are 0.9rem (14.4px). Inline code is 0.78em (15.6px; monospace looks larger at the same size). |
| 3 | P2 | **Body quotes read as asides.** (Already approved in the brief.) They were 1px, muted and italic, while `quotes/` uses 2px in ink. In this post the quote is evidence. | Same treatment as `quotes/`: ink, roman, 2px accent rule. A source (`{source="…" url="…"}`) adds an attribution line and `cite`. |
| 4 | P2 | **The sticky contents list never marks where you are.** In an 8-minute read the rail is the main wayfinding. | The current section's link is set in ink with an accent underline (`aria-current="location"`) by a 15-line inline script on posts that have a contents list. Without JS the list is static as before. |
| 5 | P2 | **The end of the post repeats itself.** The signature links Mastodon, the follow list has Feed/RSS/Mastodon/GitHub, the pager comes next, and then the footer repeats GitHub/Mastodon/Feed. That is about 13 targets, with Mastodon three times. | **Not changed: your call** (see open questions). |
| 6 | P2 | **The logo figure:** the caption was left-aligned under a centred 320px logo. In dark mode the TV's outline (`#1F2747`) is about 1.2:1 against the ground. | The caption is centred under SVG figures. The outline colour lives in the post's inline SVG, so it's a content fix (see open questions). |
| 7 | P3 | **The dek was the same size as the body,** so three grey italic lines read as a faded first paragraph. | The dek is now a standfirst: 1.3rem/1.45 on desktop, 1.15rem on mobile. |
| 8 | P3 | **Weak section and figure breaks.** h2 was only 1.24× the body on desktop, and stacked screenshots ran together at paragraph spacing. | h2 is 1.75rem on desktop (1.55rem kept on mobile), and figures have 2rem above and below. |
| 9 | P3 | **Single-word last lines (detector `straggler`):** 5 at 1440 and 7 at 390. | `text-wrap: pretty` on paragraphs and the dek. |

Minor, also done:

- No hyphenation inside links. Mobile used to split "reposito-ries".
- A quiet visited state: the underline turns muted, with no new colour.
- Captions render inline Markdown, so the "Blender Foundation's open movies" caption can link.

Minor, not done:

- **Tap targets at 390:** tags (13.6px) and nav links are about 20px tall. They pass WCAG 2.5.8 through spacing, but they are below a comfortable 44px.
- **Hairline overhang:** the pager and footer rules run 7rem past the text column on desktop.
- **Copy button:** code blocks have none.
- **Contents on mobile:** no way back to it from deep in the article.

## Detector and browser evidence (B)

- `impeccable detect` on the built page found one issue: `oversized-h1`, reported as 168px. That is a false positive: the static scan misread `clamp()`, and the rendered h1 is 48px on desktop and 32px on mobile. The scan of the layouts was clean but partial, because the scanner could not resolve Hugo's stylesheet pipe. After the changes, the scan of the article and of the sidenote sample is clean (`[]`).
- With the overlay injected, the only rule that fired was `straggler` (issue 9). No colour, contrast or layout findings.
- Overflow: none at either width or theme. Console errors: none.

## Sidenotes

Footnotes are now Tufte-style sidenotes on wide screens, built without JS:

- `_partials/sidenotes.html` copies each footnote next to its first reference as `<span class="sidenote" aria-hidden="true">`.
- From 76rem (1216px) up, CSS floats that copy into the space to the right of the measure.
- The right side was chosen because the left margin column holds the sticky contents list, and notes there would slide under it.

The endnote list stays exactly as Hugo writes it (same ids, same links, same back-references). It is what screen readers use and what narrow screens show. On wide screens it folds to zero height (still in the accessibility tree) until something targets it: following a reference or a `#fn:` link opens it. Notes with block content (lists, code) stay endnotes only.

## Questions the critique raised

1. The post has about 40 reference links, and below the contents the margin is empty. Now that sidenotes exist, should sources move into the margin so the argument reads clean, with the evidence beside it?
2. What is the one thing a reader should do at the end of a post: try it, reply, or follow? Right now the page offers all three, three times.

# aldoborrero.com

Personal website and blog. Static site, served from a Cloudflare Worker (Workers Static Assets).

## Layout

| Path | What |
| --- | --- |
| `flake.nix` | numtide/blueprint flake, `prefix = "nix"`; outputs come from files under `nix/` |
| `nix/devshell.nix` | `mkShellNoCC`: just, treefmt, hugo, pagefind, lychee, tofu, wrangler, sops/age |
| `nix/formatter.nix` | treefmt-nix (`nix fmt`) + format check wired into `nix flake check` |
| `nix/packages/tofu/` | OpenTofu with the Cloudflare provider baked in |
| `nix/packages/site/` | the site: `hugo --minify --panicOnWarning` in the sandbox, then `pagefind` for the search index, plus self-hosted fonts (`.#site.fonts`: woff2 for pages, two static TTFs for share images); also `checks.<sys>.pkgs-site` |
| `nix/checks/tfsec.nix` | tfsec over `terraform/` |
| `nix/checks/no-comments.nix`, `nix/checks/links.nix` | no content HTML comment in the built site; internal links and anchors resolve (lychee, offline) |
| `website/` | Hugo site with its own theme: `layouts/`, `assets/css/` (`tokens.css` holds every colour: five palettes, each light and dark), `assets/js/zoom.js` (the image viewer), `data/cv.toml` (the career page at `/about/`), `i18n/` (strings the theme writes inside an entry, per language), `content/`, `archetypes/`, `static/` |
| `terraform/` | OpenTofu: the Worker and its custom domain; state in R2 |
| `wrangler.jsonc` | Worker static-assets config used by `wrangler deploy` |
| `secrets/secrets.yaml` | sops (age + YubiKey) dotenv with Cloudflare / R2 credentials |
| `.rumdl.toml` | Markdown lint rules (rumdl) |

## Commands

| Command | Does |
| --- | --- |
| `just` | list recipes |
| `just serve` / `just build` | hugo dev server with drafts (copies the fonts in and runs `just reindex` first, so search works) / `nix build .#site -o result-site` |
| `just reindex` | refresh the search index `just serve` uses: a drafts build in `.cache/search-site`, indexed by pagefind into `website/static/pagefind/` (gitignored, like the fonts; never in the nix build, which makes its own). Run it while the server runs to pick up new or edited entries |
| `just new <type> <slug> [--lang es]` | new draft `website/content/<type>/YYYY-MM-DD-<slug>.md` from its archetype; type is `posts`, `til`, `notes`, `links` or `quotes`; `--lang es` writes `lang: es` |
| `just touch <file>` | set `lastmod:` to today in an entry (path from the current directory or from `website/content/`); "Updated <date>" shows once lastmod is more than a day after date |
| `just check-links` | `just build`, then lychee over the external links (`lychee.toml`: cached a day in `.lycheecache`, rate-limited per host); export `GITHUB_TOKEN` or github.com links answer 503 |
| `just fmt` / `just check` | `nix fmt` / `nix flake check` (formatting, tfsec, devshell, site) |
| `just tf-init` / `tf-plan` / `tf-apply` | OpenTofu in `terraform/` |
| `just deploy` / `just preview <alias>` | wrangler deploy / upload a preview version |
| `just secrets-edit` | edit the sops secrets |

## Content types

Five sections, all in one stream on the home page (newest first, 15 per page) and in `/atom.xml` and `/index.xml`. Each has its own index and feeds (`/<type>/atom.xml`, `/<type>/index.xml`).

- The home page: the intro (`content/_index.md`) has its h1 set at lead-paragraph size so the stream starts on the first screen, then Mastodon and GitHub (About and Feed are in the header). The column left of the stream lists the sections with their counts (Writing, TIL, Notes, Links, Quotes; only those with entries), sticky on wide screens, one line under "Latest" on narrow ones.
- Lists show previews (`_partials/item.html` on the home page, `/links/`, `/notes/`, `/quotes/` and tag pages; `_partials/entries.html` on `/posts/`, `/til/` and search), separated by a `--line` hairline. Posts are the anchors: type, date and reading time, a large title, the `description` (else the opening words, about 30 words, "Read more" when shortened) in `--muted`, and a 4:3 thumbnail on the right: the post's `image:`, else its opening image when it starts with one (`_partials/thumb.html`, 320/640 px WebP, lazy). TILs, notes and links are compact: type and date, then the title; a link's title links out and is followed by "by <who> · <domain>". Their text shows only when it is 50 words or less with no `[ALDO: …]` placeholder; a note without a title shows its opening words; a quote shows its quotation. Tags: none on the home page, at most three on section and tag pages, all of them on the entry. The preview text comes from `_partials/excerpt.html`, which drops draft placeholders.

| Type | For | Front matter beyond `title`, `slug`, `date`, `tags` |
| --- | --- | --- |
| `posts` | long form: project write-ups, stories, retrospectives | `description` (optional dek) |
| `til` | one problem solved; `/til/` groups them by topic | `topic` (one, lowercase) |
| `notes` | a short thought, a few paragraphs | `title` may be empty ("Note, <date>") |
| `links` | someone else's work plus commentary; the heading links out | `link`, `by`, optional `via` / `viaUrl` |
| `quotes` | a quotation, optional comment as the body | `quote`, `source`, `sourceUrl`, optional `context`; `title` stays empty |

- Tags work across every type: `/tags/`, `/tags/<tag>/` and per-tag feeds at `/tags/<tag>/atom.xml` and `index.xml`.
- Every feed (RSS and Atom, including the language and tag feeds) carries an `xml-stylesheet` instruction to `/feed.<hash>.xsl` (`assets/feed/feed.xsl`, built by `_partials/feed-xsl.html` with the site's CSS filled in). A browser that opens a feed shows a page in the site's look (light mode): what a feed is, the address to copy, reader apps, the latest entries. Feed readers ignore the instruction. Chromium shows a warning banner on these pages because browsers are removing XSLT; once it is gone, a browser shows the raw XML again, and readers are unaffected either way.
- Every page gets Open Graph and Twitter tags (`_partials/head.html`) and a 1200×630 share image: the entry's `image:` when set, else one drawn at build time from the light tokens (`_partials/og-image.html`). Locally, `just fonts` must have run, or pages fall back to a small card.
- Follow links (feed, Mastodon, GitHub) come from `_partials/follow.html`; Bluesky and LinkedIn appear once `params.bluesky` / `params.linkedin` are set in `hugo.toml`.

## Front matter

Every key the theme reads, for all five types unless the type is named:

| Key | What it does |
| --- | --- |
| `title` | the entry's title; may be empty for notes and quotes (a title is built for them) |
| `slug` | frozen URL slug (`just new` writes it); never change it once published |
| `date` | publication date; sets the URL and the order |
| `lastmod` | last real change (`just touch <file>`); shows "Updated <date>" when more than a day after `date`, and feeds `article:modified_time` and Atom `<updated>` |
| `draft` | `true` keeps it out of `just build` (`just serve` shows it) |
| `tags` | list of tags, any type |
| `aliases` | old URLs that redirect here; keep them when moving anything |
| `image` | the entry's image: a file in its page bundle (`peke-home.webp`) or a path under `static/images` (`/images/posts/<slug>/peke-home.webp`); JPEG, PNG or WebP, and the build fails if it doesn't resolve. A post shows it as its 4:3 thumbnail in lists (without the key, a post that opens with an image uses that one). Any entry uses it as its share image (`og:image`, cut to 1200×630 JPEG) instead of the card drawn from the title |
| `imageAlt` | with `image`: the share image's description (`og:image:alt`). The list thumbnail stays decorative (`alt=""`): the title next to it already links the post |
| `description` | posts: the dek under the title, the summary in lists and the share description |
| `topic` | TIL: one lowercase topic, groups it on `/til/` |
| `link`, `by`, `via`, `viaUrl` | links: what is linked, who made it, where it was found |
| `quote`, `source`, `sourceUrl`, `context` | quotes: the quotation and its source |
| `lang` | the entry's language: `es`, or absent for English (see Languages) |
| `translationKey` | the same value on an entry and its translation links them (see Languages) |
| `status` | `outdated`: a warning callout at the top, "This post is out of date. I wrote it in <month year>, and parts of it may no longer hold." |
| `statusNote` | with `status: outdated`, a sentence of your own after that standard text (inline Markdown) |
| `supersededBy` | content path of the entry that replaces this one (e.g. `/posts/2026-12-01-nix-repl-2026`): a "There's a newer version of this post" callout linking it, with its date |
| `supersedes` | content path of the entry this one replaces: a line "This replaces my <year> post, <title>." at the top |
| `mastodon` | URL of the toot that announces the entry (`https://fosstodon.org/@aldo/<id>`): a "Replies" block at the end with "Reply on Mastodon" and "Load replies" (see Mastodon replies); a post's sign-off links the toot instead of the profile. The build fails if it isn't a toot URL |
| `series` | name of the series the entry is part of (one; a series per language: its parts share a language): "Part N of M in <series>" at the top and the list of parts at the end; `/series/<slug>/` lists them in order |
| `seriesOrder` | with `series`: the part's position (1, 2, …). Set it on every part or on none (then the date orders them); the build fails on a mix |

- Notices come from `_partials/notices.html`, in the entry's language, above the text (after a post's hero image) and at the top of the entry in the feeds. They are Markdown callouts underneath, so they look like any other.
- The build fails if `supersededBy` or `supersedes` doesn't resolve (also when it points to a draft, in `just build`), on a `status` other than `outdated`, or on a `statusNote` without it.
- The two keys are independent: set `supersededBy` on the old entry and `supersedes` on the new one.

## Languages

One site, one stream: most entries are English, some are Spanish. An entry declares `lang: es`; without the key it is English (the site language). There is no `/es/` site or URL prefix: Spanish entries use the same dated URLs.

- Inside a Spanish entry, the strings the theme writes are Spanish: dates, reading time, "Updated", contents, callout titles, the heading-anchor label, the copy button, the image-viewer link label, the sign-off, built titles ("Nota, <fecha>"), notices. They live in `website/i18n/<lang>.toml` (`en.toml`, `es.toml`) and are read by `_partials/lang.html`, not Hugo's `T`, because `T` only knows the site language. Site chrome stays English: header, "Aa" panel, footer, pager, follow list, type labels. On a Spanish page `<html lang="es">` and the chrome carries `lang="en"`; in lists, a Spanish entry carries `lang="es"` and an "ES" tag.
- Translations: give an entry and its translation the same `translationKey`. Each shows a link to the other at the top of its header, worded in the target language ("Leer en castellano", "Read in English"), and gets `<link rel="alternate" hreflang>` for both plus `og:locale` / `og:locale:alternate`.
- Feeds: `/atom.xml` and `/index.xml` (and every section and tag feed) carry every language; each item says its own (`xml:lang` on Atom entries, `dc:language` in RSS). `/en/atom.xml`, `/en/index.xml`, `/es/atom.xml` and `/es/index.xml` carry one language each (output formats `feed*` in `hugo.toml`, templates `layouts/feed*.xml`); the home page links them with `hreflang`.
- New Spanish entry: `just new posts <slug> --lang es`. Another language needs its own `i18n/<lang>.toml` with every key of `en.toml`, and a feed pair in `hugo.toml` and `layouts/` if it should have feeds.

## Series

- Give each part `series: <name>` (the same string; it is a taxonomy, `[taxonomies] series` in `hugo.toml`). Parts can be of any type. Order is `seriesOrder` when the parts set it, else the date (`_partials/series-parts.html`).
- In an entry (`_partials/series-nav.html`, strings in the entry's language): "Part 2 of 4 in <series>" above the text, the name jumping to the list at the end; the list names every part with the current one marked (`aria-current`, bold, accent number) and the series name linking its page.
- `/series/<slug>/` (`layouts/series/term.html`) lists the parts in order with "Part N", the date and a summary, plus Atom and RSS feeds of the series; `/series/` lists every series.
- Series per language: name a Spanish series in Spanish and give it Spanish parts; the entry strings follow each entry's language, and the series pages (site chrome) mark Spanish parts with "ES". Drafts don't count in "of M" in `just build`.

## Mastodon replies

- Set `mastodon:` on an entry once its toot is out. The end of the entry gets "Replies" (`_partials/replies.html`, strings in the entry's language): a "Reply on Mastodon" link, and with JS a "Load replies" button.
- Privacy: nothing is requested from the Mastodon server until the button is clicked. Then `assets/js/replies.js` fetches `https://<server>/api/v1/statuses/<id>/context` (public, no login) and lists the public and unlisted replies: avatar, name, handle, date (linking the reply), content; replies to replies are indented up to three levels; content warnings stay folded.
- Reply HTML is rebuilt node by node from an allow-list (p, br, a, span, strong, b, em, i, code, pre, blockquote, lists, del, s): no attributes except an http(s) `href` on links, scripts, iframes, images and styles dropped. Nothing from the server goes through `innerHTML`.
- Errors (server down, toot deleted) say the replies are still on Mastodon and leave the button to retry; no replies says so.

## Link checking

- Internal links and anchors: `nix flake check` runs `nix/checks/links.nix`, lychee offline over the built site. Root-relative and `https://aldoborrero.com/` links must resolve to a file in the build (a directory needs its `index.html`), and `#fragments` to an id on that page. No network; a broken internal link fails CI.
- External links: `just check-links` locally, and `.github/workflows/links.yml` every Monday (and on demand from the Actions tab), which lists broken links in the run summary with a warning and stays green; it never touches the deploy. Settings in `lychee.toml`: excludes (this site, X/Twitter and LinkedIn, which refuse automated requests, the analytics beacon), 429 counts as OK, at most two requests at a time per host, 500 ms apart, two retries.
- Fix a broken external link in the post itself (or point it to the Internet Archive); don't add it to the excludes.

## Analytics

- Cloudflare Web Analytics, set by `params.cfAnalyticsToken` in `hugo.toml` (empty by default). Get the token in the Cloudflare dashboard: Web Analytics, "Add a site", hostname `aldoborrero.com`, then copy the token from the JS snippet it shows (choose the manual snippet, not automatic setup). The token is public (it ends up in every page), so it lives in `hugo.toml`, not in sops.
- The beacon (`static.cloudflareinsights.com/beacon.min.js`, in `baseof.html`) is added only in production builds (`just build`, CI) and only when the token is set; `just serve`, a build without a token and forks send nothing.
- No cookies, no local storage and no fingerprinting, so no consent banner is needed.
- Not owned by tofu yet: `terraform/` could manage the site as a `cloudflare_web_analytics_site` and output its token, but the hermetic build can't read tofu state, so the token would still be copied into `hugo.toml` by hand.

## Keyboard shortcuts

`assets/js/keys.js` (2.3 KB minified, 1.3 KB gzipped, no dependency) on every page; the help dialog sits in a `<template>` in `_partials/keys-help.html` and is cloned on first use.

| Key | Does |
| --- | --- |
| `/` | focus the search box on `/search/`; elsewhere open `/search/` (focused on desktop) |
| `?` | open or close the help dialog (native modal `<dialog>`, a table of `<kbd>`; Esc closes it and focus returns) |
| `j` / `k` | next / previous entry in a list: home stream, sections, `/til/`, tags, search results, series pages. Focuses the entry's link (visible focus ring) and scrolls it to the middle; from nothing focused it starts at what is on screen |
| `n` / `p` | on an entry: the pager's newer (`rel=next`) / older (`rel=prev`) entry |
| `c` | contents of a long post: the list in the margin (focus its first link) on wide screens, the sheet on narrow ones |
| `a` | open or close the "Aa" panel, focus on the current choice |
| `t` | light / dark (through the panel's radios, so it is saved like a click) |
| `g` then `h` / `p` / `t` / `a` | go to home / Writing / TIL / About (within 1.5 s) |
| `Esc` | close what is open (native for the dialogs, popovers and the image viewer) |

- Never fire while typing in a text field, select or contenteditable (radios and checkboxes don't count), with Ctrl, Alt or Meta held, or while a modal dialog is open (the image viewer keeps its own keys; in the help, only `?` and Esc). Shift is allowed, since `?` needs it and `/` needs it on a Spanish keyboard.
- Off switch: "Keyboard shortcuts" in the "Aa" panel. While on, the controls carry `aria-keyshortcuts` (search link, Aa, Contents button, pager links, the hint); off removes them.
- Discoverability: "Keyboard shortcuts ?" at the end of the footer, a button that opens the help, shown only with a fine pointer (not on touch screens) and only while shortcuts are on. The dialog is site chrome, so English.
- Adding one: an entry in `actions` in `keys.js`, a row in `keys-help.html`, and `aria-keyshortcuts` in `labels` if a control does the same.

## Search

- `/search/` (`layouts/search/page.html`, content `search.md`) searches every published entry in the browser with [Pagefind](https://pagefind.app/). The index is built in `nix build .#site` after Hugo (`nix/packages/site/package.nix`) and served from `/pagefind/`; the bundled Pagefind UI files are deleted, the page draws its own results from the tokens.
- The magnifier in the header (beside "Aa") links to `/search/`; the 404 page has a search box that opens `/search/?q=…`. `/search/?q=<words>` runs a search on load.
- What is indexed: only entries (`data-pagefind-body` on the `<article>` in `posts/page.html` and `page.html`), without their date line, contents list, sign-off, tags, follow links and pager (`data-pagefind-ignore`). Metadata: `title` (the h1), `date` (the shown date), `type` (Post, TIL, …) and `lang`.
- Languages: Pagefind writes one index per `<html lang>`; the page loads the English one and merges every other language from `pagefind-entry.json`, so one search covers both. Results in another language carry the "ES" tag.
- Pagefind 1.6 also returns loose matches (a query that only shares a few letters with a word); the page keeps a result only when a highlighted word starts like a word of the query.
- Nothing from Pagefind loads on other pages; on `/search/` it loads when the box gets focus or a query arrives. Without JS the page says search needs it and points to Writing and Tags.
- Locally, `just serve` runs `just reindex` first, so `/search/` works on the dev server too, drafts included; the index is a snapshot, so run `just reindex` again after adding or editing entries (the server picks the new files up, no restart). The production index never includes drafts.

## Images

- Write a standalone Markdown image: `![Alt text that describes it](file.webp "Optional caption")`. Put the file next to the entry (make the entry a bundle: `posts/YYYY-MM-DD-slug/index.md` plus its images) or under `website/static/images/posts/<slug>/` and use `/images/posts/<slug>/file.webp`.
- Every standalone image opens in the image viewer (`assets/js/zoom.js`, from `_markup/render-image.html`): click or tap for 1:1, wheel or pinch to zoom, drag to pan, arrows or swipe for the entry's other images, Esc / back / the close button to leave. Without JS the image is a plain link to the file.
- Images wider than 1520 px are shown downscaled (`srcset`); the original is only fetched when the viewer opens. `static/images` is mounted as `assets/images` for this (`hugo.toml`).
- Opt out: SVGs and images inside a sentence never open in the viewer. For any other image, put `{.nozoom}` on the line right after it.
- Alt text is the accessible name of the link ("Open image: <alt>"), so always write one.
- Captions (the image title) take inline Markdown, so they can link: `![Alt](file.webp "The films are the [Blender open movies](https://studio.blender.org/films/).")`.

## Quotes, callouts and footnotes

- A blockquote can carry its source as block attributes on the line right after it; it then gets an attribution line and `cite` (`_markup/render-blockquote.html`). `source` takes inline Markdown; `url` alone shows the host name (`nix fmt` may rewrite it as `url="<https://…>"`, which works too).

  ```markdown
  > So many kids are using mobile devices today…
  {source="The Child Mode request on Jellyfin's feature board" url="https://features.jellyfin.org/posts/531"}
  ```

- Footnotes (`text[^1]` … `[^1]: The note.`) show as sidenotes right of the text from 1216 px up, and as endnotes below that (`_partials/sidenotes.html`). Keep notes to inline text and links: a note with a list or code stays an endnote only.

- Callouts use GitHub's alert syntax and get an icon and a title line (same hook). Types: `NOTE`, `TIP`, `IMPORTANT` (accent hairline), `WARNING` and `CAUTION` (in `--warn`; caution with a hairline). A title of your own goes after the marker; a `{source=… url=…}` line works here too and shows as the callout's last line.

  ```markdown
  > [!WARNING] Back up first
  > The migration rewrites the database in place.
  ```

## Two perspectives

One moment from two sides (what the child sees, what the parent does), with `_shortcodes/perspectives.html` and `side.html`. Use `{{% %}}` so each side is Markdown; images keep the render hook and the zoom viewer, which steps through them in reading order (first side, then second).

```markdown
{{% perspectives title="Time's up" %}}
{{% side label="Leo sees" %}}
![Alt text](/images/posts/<slug>/peke-times-up.webp "Caption")
The film stops and the buddy says goodbye.
{{% /side %}}
{{% side label="You do" %}}
Type the parent code and add 15 minutes.
{{% /side %}}
{{% /perspectives %}}
```

- `title` is optional and renders as an h3 in raw HTML, so it stays out of the contents list. `label` is required on each side.
- A side holds text and zero to two images. Wide screens show the sides next to each other, widened up to 60rem into the right margin from 64rem; under 48rem they stack, first side first. The first label's marker is `--accent`, the second's `--ink`.

## Code blocks and headings

- Fenced code goes through `_markup/render-codeblock.html`: Chroma highlighting as before, a copy button (`_partials/code-copy.html`, added by JS, so feeds never show it; shell prompts from `console` blocks are not copied), and optional attributes on the fence:

  ````markdown
  ```nix {file="flake.nix" hl_lines=[3,4]}
  ````

  `file` shows a file-name bar above the code; `hl_lines` (Hugo's own option, 1-based lines or ranges like `"2-4"`) marks lines with `--mark`. Other Hugo highlighting options (`linenos`, `linenostart`) work as usual.
- h2 and h3 get a `#` link to themselves (`_markup/render-heading.html`), visible on hover and keyboard focus, named "Link to this section". Feeds drop it.

## Reading settings and palettes

- The "Aa" button (in the UI font) and the search link sit right after the nav, set off by a hairline (on narrow screens, on the brand's line). "Aa" opens the reading settings (`_partials/header.html`, a popover): palette, light/dark, text size (S/M/L scales the reading text, not the UI) and font (Newsreader or Hanken Grotesk). Choices are kept in `localStorage` (`palette`, `theme`, `size`, `font`) and set as `data-*` on `<html>` by the pre-paint script in `head.html`, so nothing flashes. Without JS the button stays hidden and the page uses the defaults.
- The panel's last group, "Keyboard shortcuts" On/Off (`keys` in `localStorage`, `data-keys="off"` on `<html>`), turns the single-key shortcuts off (WCAG 2.1.4); see Keyboard shortcuts.
- `params.palette` in `hugo.toml` is the default palette, and also the one share images are drawn in (light mode). The build fails if it names a palette that `tokens.css` doesn't define.
- To add or change a palette, edit only `assets/css/tokens.css`: one block `[data-palette="id"]` (light, with `--palette-name: "Shown name"`) and one `[data-theme="dark"][data-palette="id"], [data-theme="dark"] [data-palette="id"]` (dark), each with every token. The panel and the pre-paint script read the list from that file (`_partials/palettes.html`).
- Every palette and mode must pass WCAG AA (4.5:1) for: ink, muted, accent and warn on `--bg` and `--mark`; ink, muted, accent, kw and str on `--code-bg`; kw and str on `--mark` (highlighted lines); and bg on ink (the selected option in the panel).
- On narrow screens, posts with a contents list get a "Contents" button fixed at the bottom that opens the list as a sheet (`posts/page.html`, popover, works without JS).

## Invariants

- Blueprint only sees git-tracked files: `git add` new files under `nix/` before any nix command.
- Ownership split on Cloudflare: tofu owns the Worker (`cloudflare_worker`) and its domain (`cloudflare_workers_custom_domain`); wrangler only uploads versions and deploys them. `wrangler.jsonc` must not declare routes, and its `name` must match `local.worker_name`.
- Secrets are only loaded by direnv when `WEBSITE_LOAD_SECRETS=1` (see `.envrc.local-template` for the variables they provide).
- The CI deploy job is gated by the repository variable `DEPLOY_ENABLED`.
- HTML comments in content (`<!-- … -->`, the notes and open questions at the end of drafts) never reach the published site: templates take content from `_partials/content.html`, which strips them, never `.Content` directly. `--minify` already drops them from pages, but feeds carry entry HTML escaped and unminified. `nix flake check` runs `checks/no-comments.nix`, which fails on `<!--` in any page or the feed stylesheet and on an escaped `&lt;!--` in any feed (a comment shown as code is escaped once more and passes). There are no legitimate comments in the output to allow; the theme's own template comments use `{{/* */}}`.
- The site build has no network access and fails on any Hugo warning; after a nixpkgs bump, fix deprecations in `website/layouts/` before merging.
- Entry URLs are `/<type>/:year/:month/:day/:slug/` with `slug:` frozen in each entry's front matter (`just new` writes it); keep `aliases:` and `website/static/_redirects` when moving anything. `/index.xml` and `/posts/index.xml` have subscribers: never move them.
- `wrangler.jsonc` deploys `./result-site`, so run `just build` before `just deploy` or `just preview`.

## Pending: cutover from Cloudflare Pages

Production still runs on the old Pages project (`aldoborrero-website`, CNAME `@` → `aldoborrero-website.pages.dev`), whose state sits in the old DigitalOcean Spaces backend. That state is not migrated; the new configuration starts with fresh state in R2.

1. Done on `feat/hugo-theme`: `just build` produces `./result-site`.
2. Create the R2 bucket `aldoborrero-tfstate` and an R2 API token; put `CLOUDFLARE_ACCOUNT_ID`, `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `AWS_ENDPOINT_URL_S3` and an updated `CLOUDFLARE_API_TOKEN` into `secrets/secrets.yaml`.
3. `just tf-init`, then `tofu -chdir=terraform apply -target=cloudflare_worker.website`, and `just build && just deploy` to give the Worker its first version.
4. Remove the Pages custom domain and the apex CNAME (dashboard), then `just tf-apply` to attach `aldoborrero.com` to the Worker. The site is down between these two steps.
5. Verify, delete the Pages project, add GitHub secrets `CLOUDFLARE_API_TOKEN` / `CLOUDFLARE_ACCOUNT_ID`, and set `DEPLOY_ENABLED=true`.

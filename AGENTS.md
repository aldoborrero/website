# aldoborrero.com

Personal website and blog. Static site, served from a Cloudflare Worker (Workers Static Assets).

## Layout

| Path | What |
| --- | --- |
| `flake.nix` | numtide/blueprint flake, `prefix = "nix"`; outputs come from files under `nix/` |
| `nix/devshell.nix` | `mkShellNoCC`: just, treefmt, hugo, tofu, wrangler, sops/age |
| `nix/formatter.nix` | treefmt-nix (`nix fmt`) + format check wired into `nix flake check` |
| `nix/packages/tofu/` | OpenTofu with the Cloudflare provider baked in |
| `nix/packages/site/` | the site: `hugo --minify --panicOnWarning` in the sandbox, plus self-hosted fonts (`.#site.fonts`: woff2 for pages, two static TTFs for share images); also `checks.<sys>.pkgs-site` |
| `nix/checks/tfsec.nix` | tfsec over `terraform/` |
| `website/` | Hugo site with its own theme: `layouts/`, `assets/css/` (`tokens.css` holds every colour; light by default, dark through the header toggle), `assets/js/zoom.js` (the image viewer), `data/cv.toml` (the career page at `/about/`), `content/`, `archetypes/`, `static/` |
| `terraform/` | OpenTofu: the Worker and its custom domain; state in R2 |
| `wrangler.jsonc` | Worker static-assets config used by `wrangler deploy` |
| `secrets/secrets.yaml` | sops (age + YubiKey) dotenv with Cloudflare / R2 credentials |
| `.rumdl.toml` | Markdown lint rules (rumdl) |

## Commands

| Command | Does |
| --- | --- |
| `just` | list recipes |
| `just serve` / `just build` | hugo dev server with drafts (copies the fonts in first) / `nix build .#site -o result-site` |
| `just new <type> <slug>` | new draft `website/content/<type>/YYYY-MM-DD-<slug>.md` from its archetype; type is `posts`, `til`, `notes`, `links` or `quotes` |
| `just fmt` / `just check` | `nix fmt` / `nix flake check` (formatting, tfsec, devshell, site) |
| `just tf-init` / `tf-plan` / `tf-apply` | OpenTofu in `terraform/` |
| `just deploy` / `just preview <alias>` | wrangler deploy / upload a preview version |
| `just secrets-edit` | edit the sops secrets |

## Content types

Five sections, all in one stream on the home page (newest first, 15 per page) and in `/atom.xml` and `/index.xml`. Each has its own index and feeds (`/<type>/atom.xml`, `/<type>/index.xml`).

| Type | For | Front matter beyond `title`, `slug`, `date`, `tags` |
| --- | --- | --- |
| `posts` | long form: project write-ups, stories, retrospectives | `description` (optional dek) |
| `til` | one problem solved; `/til/` groups them by topic | `topic` (one, lowercase) |
| `notes` | a short thought, a few paragraphs | `title` may be empty ("Note, <date>") |
| `links` | someone else's work plus commentary; the heading links out | `link`, `by`, optional `via` / `viaUrl` |
| `quotes` | a quotation, optional comment as the body | `quote`, `source`, `sourceUrl`, optional `context`; `title` stays empty |

- Tags work across every type: `/tags/`, `/tags/<tag>/` and per-tag feeds at `/tags/<tag>/atom.xml` and `index.xml`.
- Every page gets Open Graph and Twitter tags (`_partials/head.html`) and a 1200×630 share image drawn at build time from the light tokens (`_partials/og-image.html`). Locally, `just fonts` must have run, or pages fall back to a small card.
- Follow links (feed, Mastodon, GitHub) come from `_partials/follow.html`; Bluesky and LinkedIn appear once `params.bluesky` / `params.linkedin` are set in `hugo.toml`.
- Samples in each new section are `draft: true` lorem ipsum: visible with `just serve`, never in `just build`.

## Images

- Write a standalone Markdown image: `![Alt text that describes it](file.webp "Optional caption")`. Put the file next to the entry (make the entry a bundle: `posts/YYYY-MM-DD-slug/index.md` plus its images) or under `website/static/images/posts/<slug>/` and use `/images/posts/<slug>/file.webp`.
- Every standalone image opens in the image viewer (`assets/js/zoom.js`, from `_markup/render-image.html`): click or tap for 1:1, wheel or pinch to zoom, drag to pan, arrows or swipe for the entry's other images, Esc / back / the close button to leave. Without JS the image is a plain link to the file.
- Images wider than 1520 px are shown downscaled (`srcset`); the original is only fetched when the viewer opens. `static/images` is mounted as `assets/images` for this (`hugo.toml`).
- Opt out: SVGs and images inside a sentence never open in the viewer. For any other image, put `{.nozoom}` on the line right after it.
- Alt text is the accessible name of the link ("Open image: <alt>"), so always write one.

## Invariants

- Blueprint only sees git-tracked files: `git add` new files under `nix/` before any nix command.
- Ownership split on Cloudflare: tofu owns the Worker (`cloudflare_worker`) and its domain (`cloudflare_workers_custom_domain`); wrangler only uploads versions and deploys them. `wrangler.jsonc` must not declare routes, and its `name` must match `local.worker_name`.
- Secrets are only loaded by direnv when `WEBSITE_LOAD_SECRETS=1` (see `.envrc.local-template` for the variables they provide).
- The CI deploy job is gated by the repository variable `DEPLOY_ENABLED`.
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

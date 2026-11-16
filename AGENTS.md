# aldoborrero.com

Personal website and blog. Static site, served from a Cloudflare Worker (Workers Static Assets).

## Layout

| Path | What |
| --- | --- |
| `flake.nix` | numtide/blueprint flake, `prefix = "nix"`; outputs come from files under `nix/` |
| `nix/devshell.nix` | `mkShellNoCC`: just, treefmt, hugo, go, tofu, wrangler, sops/age |
| `nix/formatter.nix` | treefmt-nix (`nix fmt`) + format check wired into `nix flake check` |
| `nix/packages/tofu/` | OpenTofu with the Cloudflare provider baked in |
| `nix/checks/tfsec.nix` | tfsec over `terraform/` |
| `website/` | Hugo site (content, config, static assets) |
| `terraform/` | OpenTofu: the Worker and its custom domain; state in R2 |
| `wrangler.jsonc` | Worker static-assets config used by `wrangler deploy` |
| `secrets/secrets.yaml` | sops (age + YubiKey) dotenv with Cloudflare / R2 credentials |
| `.rumdl.toml` | Markdown lint rules (rumdl) |

## Commands

| Command | Does |
| --- | --- |
| `just` | list recipes |
| `just serve` / `just build` | hugo dev server / build into `website/public` |
| `just fmt` / `just check` | `nix fmt` / `nix flake check` (formatting, tfsec, devshell) |
| `just tf-init` / `tf-plan` / `tf-apply` | OpenTofu in `terraform/` |
| `just deploy` / `just preview <alias>` | wrangler deploy / upload a preview version |
| `just secrets-edit` | edit the sops secrets |

## Invariants

- Blueprint only sees git-tracked files: `git add` new files under `nix/` before any nix command.
- Ownership split on Cloudflare: tofu owns the Worker (`cloudflare_worker`) and its domain (`cloudflare_workers_custom_domain`); wrangler only uploads versions and deploys them. `wrangler.jsonc` must not declare routes, and its `name` must match `local.worker_name`.
- Secrets are only loaded by direnv when `WEBSITE_LOAD_SECRETS=1` (see `.envrc.local-template` for the variables they provide).
- The CI deploy job is gated by the repository variable `DEPLOY_ENABLED`.

## Pending: cutover from Cloudflare Pages

Production still runs on the old Pages project (`aldoborrero-website`, CNAME `@` → `aldoborrero-website.pages.dev`), whose state sits in the old DigitalOcean Spaces backend. That state is not migrated; the new configuration starts with fresh state in R2.

1. Make the site build again (blog engine decision) so `just build` produces `website/public`.
2. Create the R2 bucket `aldoborrero-tfstate` and an R2 API token; put `CLOUDFLARE_ACCOUNT_ID`, `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `AWS_ENDPOINT_URL_S3` and an updated `CLOUDFLARE_API_TOKEN` into `secrets/secrets.yaml`.
3. `just tf-init`, then `tofu -chdir=terraform apply -target=cloudflare_worker.website`, and `just build && just deploy` to give the Worker its first version.
4. Remove the Pages custom domain and the apex CNAME (dashboard), then `just tf-apply` to attach `aldoborrero.com` to the Worker. The site is down between these two steps.
5. Verify, delete the Pages project, add GitHub secrets `CLOUDFLARE_API_TOKEN` / `CLOUDFLARE_ACCOUNT_ID`, and set `DEPLOY_ENABLED=true`.

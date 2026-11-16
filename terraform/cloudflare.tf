# Cloudflare infrastructure for aldoborrero.com.
#
# Ownership split (as recommended in Cloudflare's Workers IaC docs):
#   - tofu owns the Worker itself and the domains it serves.
#   - wrangler (CI, wrangler.jsonc) uploads versions with the static assets
#     and deploys them.

locals {
  domain      = "aldoborrero.com"
  worker_name = "aldoborrero-website"
  account_id  = data.cloudflare_zone.domain.account.id
}

data "cloudflare_zone" "domain" {
  filter = {
    name = local.domain
  }
}

# --------------------------------------------
# Worker serving the static site
# --------------------------------------------

resource "cloudflare_worker" "website" {
  account_id = local.account_id
  name       = local.worker_name

  observability = {
    enabled = true
  }

  # Served only on the custom domain; *.workers.dev stays off, but preview
  # URLs for pull requests are enabled.
  subdomain = {
    enabled          = false
    previews_enabled = true
  }
}

resource "cloudflare_workers_custom_domain" "website" {
  account_id = local.account_id
  zone_id    = data.cloudflare_zone.domain.id
  hostname   = local.domain
  service    = cloudflare_worker.website.name
}

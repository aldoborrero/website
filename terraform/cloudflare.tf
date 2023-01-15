locals {
  domain         = "aldoborrero.com"
  cf_pages_name  = "aldoborrero-website"
  git_repo_owner = "aldoborrero"
  git_repo_name  = "website"
  hugo_version   = "0.106.0"
}

# --------------------------------------------
# Data
# --------------------------------------------

data "cloudflare_zone" "domain" {
  name = local.domain
}

# --------------------------------------------
# Cloudflare Pages: Website
# --------------------------------------------

resource "cloudflare_pages_project" "website" {
  account_id        = data.cloudflare_zone.domain.account_id
  name              = local.cf_pages_name
  production_branch = "main"

  source {
    type = "github"
    config {
      owner                         = local.git_repo_owner
      repo_name                     = local.git_repo_name
      production_branch             = "main"
      pr_comments_enabled           = true
      deployments_enabled           = true
      production_deployment_enabled = true
      preview_deployment_setting    = "custom"
      preview_branch_includes       = ["develop"]
      preview_branch_excludes       = ["main"]
    }
  }

  build_config {
    build_command   = "hugo --minify --source ./website"
    destination_dir = "website/public"
  }

  deployment_configs {
    preview {
      environment_variables = {
        HUGO_VERSION = local.hugo_version
      }
    }
    production {
      environment_variables = {
        HUGO_VERSION = local.hugo_version
      }
    }
  }
}

resource "cloudflare_pages_domain" "website" {
  depends_on = [cloudflare_pages_project.website]

  account_id   = data.cloudflare_zone.domain.account_id
  project_name = local.cf_pages_name
  domain       = local.domain
}

# --------------------------------------------
# Cloudflare Records
# --------------------------------------------

resource "cloudflare_record" "website" {
  zone_id = data.cloudflare_zone.domain.zone_id
  name    = "@"
  proxied = true
  ttl     = 1
  type    = "CNAME"
  value   = "${local.cf_pages_name}.pages.dev"
}

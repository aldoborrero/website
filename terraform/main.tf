# --------------------------------------------
# Data
# --------------------------------------------

data "cloudflare_zone" "domain" {
  name = "aldoborrero.com"
}

# --------------------------------------------
# Cloudflare Pages: Website
# --------------------------------------------

resource "cloudflare_pages_project" "website" {
  account_id        = data.cloudflare_zone.domain.account_id
  name              = "aldoborrero-website"
  production_branch = "main"

  source {
    type = "github"
    config {
      owner                         = "aldoborrero"
      repo_name                     = "website"
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
        HUGO_VERSION = "0.106.0"
      }
    }
    production {
      environment_variables = {
        HUGO_VERSION = "0.106.0"
      }
    }
  }
}

resource "cloudflare_pages_domain" "website" {
  depends_on = [cloudflare_pages_project.website]

  account_id   = data.cloudflare_zone.domain.account_id
  project_name = "aldoborrero-website"
  domain       = "aldoborrero.com"
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
  value   = "aldoborrero-website.pages.dev"
}

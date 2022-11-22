terraform {
  required_providers {
    cloudflare = { source = "cloudflare/cloudflare" }
    external   = { source = "hashicorp/external" }
    null       = { source = "hashicorp/null" }
    random     = { source = "hashicorp/random" }
    secret     = { source = "numtide/secret" }
    time       = { source = "hashicorp/time" }
    tls        = { source = "hashicorp/tls" }
  }

  backend "s3" {
    bucket                      = "nyx-tf"
    encrypt                     = true
    key                         = "targets/website"
    region                      = "fra-1"
    endpoint                    = "fra1.digitaloceanspaces.com"
    skip_credentials_validation = true
    skip_metadata_api_check     = true
    skip_region_validation      = true
  }
}

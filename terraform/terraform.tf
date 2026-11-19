terraform {
  required_version = ">= 1.10"

  # State lives in Cloudflare R2 (S3-compatible). The endpoint is account
  # specific and comes from AWS_ENDPOINT_URL_S3, the credentials from
  # AWS_ACCESS_KEY_ID / AWS_SECRET_ACCESS_KEY (an R2 API token); all three are
  # exported from secrets/secrets.yaml by .envrc.
  backend "s3" {
    bucket       = "aldoborrero-tfstate"
    key          = "website/terraform.tfstate"
    region       = "auto"
    use_lockfile = true # S3-native locking, supported by R2

    use_path_style              = true
    skip_credentials_validation = true
    skip_metadata_api_check     = true
    skip_region_validation      = true
    skip_requesting_account_id  = true
    skip_s3_checksum            = true
  }

  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 5.27"
    }
  }
}

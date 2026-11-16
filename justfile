# aldoborrero.com

site := "website"
tf := "terraform"

default:
    @just --list

# Run the hugo dev server with drafts
serve *args:
    hugo server --source {{ site }} --buildDrafts {{ args }}

# Build the site into website/public, as Cloudflare Pages does
build:
    hugo --minify --source {{ site }}

# Update the hugo theme module
update-theme:
    cd {{ site }} && hugo mod get -u && hugo mod tidy

# Format everything (nix, markdown, shell, yaml, toml, json, hcl)
fmt:
    nix fmt

# Every check CI runs
check:
    nix flake check --log-format bar-with-logs

# Update flake inputs
update:
    nix flake update

# tofu init against the R2 state backend
tf-init:
    tofu -chdir={{ tf }} init

# tofu plan
tf-plan:
    tofu -chdir={{ tf }} plan

# tofu apply
tf-apply:
    tofu -chdir={{ tf }} apply

# Edit the encrypted secrets
secrets-edit:
    sops secrets/secrets.yaml

# Re-encrypt secrets after changing recipients in .sops.yaml
secrets-updatekeys:
    sops updatekeys --yes secrets/secrets.yaml

# Deploy website/public to the Worker (run `just build` first)
deploy:
    wrangler deploy

# Upload a preview version (prints its preview URL) without deploying it
preview alias:
    wrangler versions upload --preview-alias {{ alias }}

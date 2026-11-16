# aldoborrero.com

site := "website"
tf := "terraform"

default:
    @just --list

# Run the hugo dev server with drafts (fonts come from the nix build)
serve *args: fonts
    hugo server --source {{ site }} --buildDrafts {{ args }}

# Build the site with nix into ./result-site (what wrangler deploys)
build:
    nix build .#site -o result-site

# Copy the self-hosted fonts into website/static/fonts for `hugo server`
fonts:
    nix build .#site.fonts -o result-fonts
    mkdir -p {{ site }}/static/fonts
    install -m 644 result-fonts/*.woff2 {{ site }}/static/fonts/

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

# Deploy ./result-site to the Worker (run `just build` first)
deploy:
    wrangler deploy

# Upload a preview version (prints its preview URL) without deploying it
preview alias:
    wrangler versions upload --preview-alias {{ alias }}

# Restore the agent skills pinned in skills-lock.json into .claude/skills
skills:
    nix shell nixpkgs#nodejs --command npx -y skills experimental_install --agent claude-code

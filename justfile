# aldoborrero.com

site := "website"
tf := "terraform"

default:
    @just --list

# Run the hugo dev server with drafts (fonts come from the nix build)
serve *args: fonts
    hugo server --source {{ site }} --buildDrafts {{ args }}

# Drafts build with the search index, served by pagefind at http://localhost:1414
# (`just serve` has no index, so /search/ only works here and in `just build`)
search: fonts
    rm -rf .cache/search-site
    hugo --source {{ site }} --buildDrafts --quiet --destination "{{ justfile_directory() }}/.cache/search-site"
    pagefind --site .cache/search-site --serve

# Build the site with nix into ./result-site (what wrangler deploys)
build:
    nix build .#site -o result-site

# Copy the self-hosted fonts for `hugo server`: woff2 for pages, TTF for share images
fonts:
    nix build .#site.fonts -o result-fonts
    mkdir -p {{ site }}/static/fonts {{ site }}/assets/fonts
    install -m 644 result-fonts/*.woff2 {{ site }}/static/fonts/
    install -m 644 result-fonts/*.ttf {{ site }}/assets/fonts/

# New draft entry: just new <posts|til|notes|links|quotes> <slug> [--lang es]
new type slug *flags:
    #!/usr/bin/env bash
    set -euo pipefail
    case "{{ type }}" in posts|til|notes|links|quotes) ;; *) echo "type must be posts, til, notes, links or quotes" >&2; exit 1 ;; esac
    lang=""
    set -- {{ flags }}
    while [ $# -gt 0 ]; do
      case "$1" in
        --lang) lang="${2:?--lang needs a language, e.g. --lang es}"; shift 2 ;;
        --lang=*) lang="${1#--lang=}"; shift ;;
        *) echo "unknown option: $1 (only --lang <code>)" >&2; exit 1 ;;
      esac
    done
    if [ -n "$lang" ] && [ ! -f "{{ site }}/i18n/$lang.toml" ]; then echo "no strings for \"$lang\": add {{ site }}/i18n/$lang.toml first" >&2; exit 1; fi
    # The archetypes write `lang:` from params.newlang; en is the default, so no key.
    if [ -n "$lang" ] && [ "$lang" != en ]; then export HUGO_PARAMS_NEWLANG="$lang"; fi
    hugo new content --source {{ site }} --kind {{ type }} "{{ type }}/$(date +%Y-%m-%d)-{{ slug }}.md"

# Set lastmod to today in an entry's front matter (adds the key after date:)
touch file:
    #!/usr/bin/env bash
    set -euo pipefail
    cd "{{ invocation_directory() }}"
    f="{{ file }}"
    [ -f "$f" ] || f="{{ justfile_directory() }}/{{ site }}/content/{{ file }}"
    [ -f "$f" ] || { echo "no such entry: {{ file }}" >&2; exit 1; }
    [ "$(head -n1 "$f")" = "---" ] || { echo "$f: front matter must be YAML (---)" >&2; exit 1; }
    today=$(date +%Y-%m-%d)
    has=$(awk 'NR>1 && /^---$/ {exit} /^lastmod:/ {print "yes"; exit}' "$f")
    awk -v d="$today" -v has="$has" '
      NR > 1 && fm && /^---$/ { fm = 0 }
      NR == 1 { fm = 1 }
      fm && has && /^lastmod:/ { print "lastmod: " d; next }
      { print }
      fm && !has && /^date:/ { print "lastmod: " d }
    ' "$f" > "$f.tmp" && mv "$f.tmp" "$f"
    grep -m1 "^lastmod:" "$f"

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

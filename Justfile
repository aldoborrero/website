# just is a handy way to save and run project-specific commands.
#
# https://github.com/casey/just

# Default command
default:
  just --list

# Formats code
fmt:
  treefmt
alias f := fmt

# Shortcut to interact with tfsec
tfsec *ARGS='':
  @tfsec terraform {{ARGS}}

# Cleans any result produced by Nix or associated tools
clean:
  rm -rf result* *.qcow2
alias c := clean

# Edit secrets
sops-edit:
  sops secrets/secrets.yaml

# Re-encrypt secrets with the updated set of keys in .sops.yaml
sops-update-keys:
  sops updatekeys --yes secrets/secrets.yaml

# Runs hugo server in development mode
hugo-server:
  hugo server --source ./website

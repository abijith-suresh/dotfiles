#!/usr/bin/env bash
set -euo pipefail

install_dir="$(cd "$(dirname "$0")/../.." && pwd)"

# shellcheck disable=SC1091
source "$install_dir/lib/uninstall.sh"

stow_remove tmux
remove_path "$HOME/.tmux/plugins/tpm"
ui_banner_success "tmux uninstall complete" "config + TPM removed"

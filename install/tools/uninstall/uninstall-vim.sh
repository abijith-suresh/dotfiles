#!/usr/bin/env bash
set -euo pipefail

install_dir="$(cd "$(dirname "$0")/../.." && pwd)"

# shellcheck disable=SC1091
source "$install_dir/lib/uninstall.sh"

stow_remove vim
remove_path "$HOME/.vim/pack/vendor/start/catppuccin"
ui_banner_success "Vim uninstall complete" "config + Catppuccin plugin removed"

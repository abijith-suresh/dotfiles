#!/usr/bin/env bash
set -euo pipefail

install_dir="$(cd "$(dirname "$0")/../.." && pwd)"

# shellcheck disable=SC1091
source "$install_dir/lib/uninstall.sh"

stow_remove nvim
remove_path "$HOME/.vim/pack/vendor/start/catppuccin"
ui_banner_success "Neovim uninstall complete" "config + repo-installed plugin removed"

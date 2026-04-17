#!/usr/bin/env bash
set -euo pipefail

install_dir="$(cd "$(dirname "$0")/../.." && pwd)"

# shellcheck disable=SC1091
source "$install_dir/lib/uninstall.sh"

stow_remove fzf
remove_bin fzf
ui_banner_success "fzf uninstall complete" "config + local binary removed"

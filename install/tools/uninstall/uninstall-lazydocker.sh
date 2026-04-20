#!/usr/bin/env bash
set -euo pipefail

install_dir="$(cd "$(dirname "$0")/../.." && pwd)"

# shellcheck disable=SC1091
source "$install_dir/lib/uninstall.sh"

stow_remove lazydocker
remove_bin lazydocker
ui_banner_success "lazydocker uninstall complete" "config removed · local binary removed"

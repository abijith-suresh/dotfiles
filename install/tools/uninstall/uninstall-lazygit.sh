#!/usr/bin/env bash
set -euo pipefail

install_dir="$(cd "$(dirname "$0")/../.." && pwd)"

# shellcheck disable=SC1091
source "$install_dir/lib/uninstall.sh"

remove_bin lazygit
remove_config_dir "$HOME/.config/lazygit"
ui_banner_success "lazygit uninstall complete" "local binary removed"

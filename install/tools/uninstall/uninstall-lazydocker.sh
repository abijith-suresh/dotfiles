#!/usr/bin/env bash
set -euo pipefail

install_dir="$(cd "$(dirname "$0")/../.." && pwd)"

# shellcheck disable=SC1091
source "$install_dir/lib/uninstall.sh"

remove_bin lazydocker
remove_config_dir "$HOME/.config/lazydocker"
ui_banner_success "lazydocker uninstall complete" "local binary removed"

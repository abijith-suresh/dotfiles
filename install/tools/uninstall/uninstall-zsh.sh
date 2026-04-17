#!/usr/bin/env bash
set -euo pipefail

install_dir="$(cd "$(dirname "$0")/../.." && pwd)"

# shellcheck disable=SC1091
source "$install_dir/lib/uninstall.sh"

stow_remove zsh
remove_path "${XDG_DATA_HOME:-$HOME/.local/share}/zinit/zinit.git"
ui_warn "Default shell was not changed back automatically."
ui_banner_success "zsh uninstall complete" "config + Zinit removed"

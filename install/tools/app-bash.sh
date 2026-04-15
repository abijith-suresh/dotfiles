#!/usr/bin/env bash
# Stow bash configuration

set -euo pipefail

install_dir="$(cd "$(dirname "$0")/.." && pwd)"
dotfiles_dir="$(cd "$install_dir/.." && pwd)"

# shellcheck disable=SC1091
source "$install_dir/lib/stow.sh"

manage_stow_packages "$dotfiles_dir" bash

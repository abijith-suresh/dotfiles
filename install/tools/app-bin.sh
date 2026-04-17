#!/usr/bin/env bash
# Stow helper binaries such as dotfiles CLI

set -euo pipefail

install_dir="$(cd "$(dirname "$0")/.." && pwd)"
dotfiles_dir="$(cd "$install_dir/.." && pwd)"

# shellcheck disable=SC1091
source "$install_dir/lib/common.sh"
# shellcheck disable=SC1091
source "$install_dir/lib/stow.sh"

ensure_dir "$HOME/.local/bin"
manage_stow_packages "$dotfiles_dir" bin

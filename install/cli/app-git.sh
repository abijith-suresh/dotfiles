#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="${DOTFILES_DIR:-$(cd "$(dirname "$0")/../.." && pwd)}"
source "$DOTFILES_DIR/install/pkg.sh"

pkg_install git
mkdir -p "$HOME/.config/git"
cd "$DOTFILES_DIR/configs" && stow --restow git

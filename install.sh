#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"
export DOTFILES_DIR

source "$DOTFILES_DIR/install/pkg.sh"

echo "==> Bootstrapping system dependencies..."
bash "$DOTFILES_DIR/install/bootstrap/packages.sh"

pkg_update

echo "==> Installing CLI tools..."
for installer in "$DOTFILES_DIR/install/cli/"*.sh; do
  [ -f "$installer" ] && bash "$installer"
done

echo "==> Installing languages..."
for installer in "$DOTFILES_DIR/install/languages/"*.sh; do
  [ -f "$installer" ] && bash "$installer"
done

echo "==> Stowing configuration packages..."
cd "$DOTFILES_DIR/configs"
for pkg in */; do
  pkg_name="${pkg%/}"
  [ "$pkg_name" = ".stowrc" ] && continue
  stow --restow "$pkg_name" 2>/dev/null || true
done

echo "==> Done! Open a new shell or source your config."

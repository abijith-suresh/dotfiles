#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="${DOTFILES_DIR:-$(cd "$(dirname "$0")/../.." && pwd)}"

if command -v zellij >/dev/null 2>&1; then
  echo "zellij already installed: $(zellij --version)"
  cd "$DOTFILES_DIR/configs" && stow --restow zellij
  exit 0
fi

cd /tmp
wget -qO zellij.tar.gz https://github.com/zellij-org/zellij/releases/latest/download/zellij-x86_64-unknown-linux-musl.tar.gz
tar -xf zellij.tar.gz zellij
install_dir="$HOME/.local/bin"
mkdir -p "$install_dir"
install zellij "$install_dir"
rm zellij.tar.gz zellij

cd "$DOTFILES_DIR/configs" && stow --restow zellij

echo "zellij installed to $install_dir"

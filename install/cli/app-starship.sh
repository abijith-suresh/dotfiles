#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="${DOTFILES_DIR:-$(cd "$(dirname "$0")/../.." && pwd)}"

if command -v starship >/dev/null 2>&1; then
  echo "starship already installed: $(starship --version)"
else
  mkdir -p "$HOME/.local/bin"
  curl -fsSL https://starship.rs/install.sh | sh -s -- -y -b "$HOME/.local/bin"
  echo "starship installed"
fi

cd "$DOTFILES_DIR/configs" && stow --restow starship

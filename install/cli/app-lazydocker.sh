#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="${DOTFILES_DIR:-$(cd "$(dirname "$0")/../.." && pwd)}"

if command -v lazydocker >/dev/null 2>&1; then
  echo "lazydocker already installed: $(lazydocker --version | head -1)"
else
  cd /tmp
  LAZYDOCKER_VERSION=$(curl -s https://api.github.com/repos/jesseduffield/lazydocker/releases/latest | grep -Po '"tag_name": "v\K[^"]*')
  curl -sLo lazydocker.tar.gz "https://github.com/jesseduffield/lazydocker/releases/latest/download/lazydocker_${LAZYDOCKER_VERSION}_Linux_x86_64.tar.gz"
  tar -xf lazydocker.tar.gz lazydocker
  mkdir -p "$HOME/.local/bin"
  install lazydocker "$HOME/.local/bin"
  rm lazydocker.tar.gz lazydocker
  echo "lazydocker installed: v${LAZYDOCKER_VERSION}"
fi

cd "$DOTFILES_DIR/configs" && stow --restow lazydocker

#!/usr/bin/env bash
# Install lazydocker and stow its config

set -euo pipefail

install_dir="$(cd "$(dirname "$0")/.." && pwd)"
dotfiles_dir="$(cd "$install_dir/.." && pwd)"

# shellcheck disable=SC1091
source "$install_dir/lib/common.sh"
# shellcheck disable=SC1091
source "$install_dir/lib/stow.sh"

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

manage_stow_packages "$dotfiles_dir" lazydocker

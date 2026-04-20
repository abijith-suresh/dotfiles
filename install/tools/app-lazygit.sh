#!/usr/bin/env bash
# Install lazygit and stow its config

set -euo pipefail

install_dir="$(cd "$(dirname "$0")/.." && pwd)"
dotfiles_dir="$(cd "$install_dir/.." && pwd)"

# shellcheck disable=SC1091
source "$install_dir/lib/common.sh"
# shellcheck disable=SC1091
source "$install_dir/lib/stow.sh"

if command -v lazygit >/dev/null 2>&1; then
  echo "lazygit already installed: $(lazygit --version | head -1)"
else
  cd /tmp
  LAZYGIT_VERSION=$(curl -s https://api.github.com/repos/jesseduffield/lazygit/releases/latest | grep -Po '"tag_name": "v\K[^"]*')
  curl -sLo lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/latest/download/lazygit_${LAZYGIT_VERSION}_Linux_x86_64.tar.gz"
  tar -xf lazygit.tar.gz lazygit
  mkdir -p "$HOME/.local/bin"
  install lazygit "$HOME/.local/bin"
  rm lazygit.tar.gz lazygit
  echo "lazygit installed: v${LAZYGIT_VERSION}"
fi

manage_stow_packages "$dotfiles_dir" lazygit

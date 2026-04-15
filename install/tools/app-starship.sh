#!/usr/bin/env bash
# Install Starship prompt and stow its config

set -euo pipefail

install_dir="$(cd "$(dirname "$0")/.." && pwd)"
dotfiles_dir="$(cd "$install_dir/.." && pwd)"

# shellcheck disable=SC1091
source "$install_dir/lib/common.sh"
# shellcheck disable=SC1091
source "$install_dir/lib/stow.sh"

if command -v starship >/dev/null 2>&1; then
  echo "starship already installed: $(starship --version)"
else
  ensure_dir "$HOME/.local/bin"
  curl -fsSL https://starship.rs/install.sh | sh -s -- -y -b "$HOME/.local/bin"
  echo "starship installed"
fi

manage_stow_packages "$dotfiles_dir" starship

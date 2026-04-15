#!/usr/bin/env bash
# Install latest fzf from GitHub (apt version is often too old)

set -euo pipefail

install_dir="$(cd "$(dirname "$0")/.." && pwd)"
dotfiles_dir="$(cd "$install_dir/.." && pwd)"

# shellcheck disable=SC1091
source "$install_dir/lib/common.sh"
# shellcheck disable=SC1091
source "$install_dir/lib/stow.sh"

fzf_latest=$(curl -fsSL https://api.github.com/repos/junegunn/fzf/releases/latest \
  | grep '"tag_name"' \
  | sed -E 's/.*"v([^"]+)".*/\1/')

if [ -z "$fzf_latest" ]; then
  echo "Could not fetch latest fzf version — skipping"
  exit 0
fi

fzf_installed=$(fzf --version 2>/dev/null | cut -d' ' -f1 || true)
if [ "$fzf_installed" = "$fzf_latest" ]; then
  echo "fzf already installed: $fzf_latest"
  manage_stow_packages "$dotfiles_dir" fzf
  exit 0
fi

ensure_dir "$HOME/.local/bin"
curl -fsSL "https://github.com/junegunn/fzf/releases/download/v${fzf_latest}/fzf-${fzf_latest}-linux_amd64.tar.gz" \
  | tar -xz -C "$HOME/.local/bin" fzf

manage_stow_packages "$dotfiles_dir" fzf

echo "fzf installed: $fzf_latest"

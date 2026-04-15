#!/usr/bin/env bash
# Install Zellij and stow its config

set -euo pipefail

repo_install_dir="$(cd "$(dirname "$0")/.." && pwd)"
dotfiles_dir="$(cd "$repo_install_dir/.." && pwd)"

# shellcheck disable=SC1091
source "$repo_install_dir/lib/common.sh"
# shellcheck disable=SC1091
source "$repo_install_dir/lib/stow.sh"

if command -v zellij >/dev/null 2>&1; then
  echo "zellij already installed: $(zellij --version)"
  manage_stow_packages "$dotfiles_dir" zellij
  exit 0
fi

cd /tmp
wget -qO zellij.tar.gz https://github.com/zellij-org/zellij/releases/latest/download/zellij-x86_64-unknown-linux-musl.tar.gz
tar -xf zellij.tar.gz zellij
install_dir="$HOME/.local/bin"
mkdir -p "$install_dir"
install zellij "$install_dir"
rm zellij.tar.gz zellij

manage_stow_packages "$dotfiles_dir" zellij

echo "zellij installed to $install_dir"

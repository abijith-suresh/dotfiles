#!/usr/bin/env bash
# Install Zellij

set -euo pipefail

if command -v zellij >/dev/null 2>&1; then
  echo "zellij already installed: $(zellij --version)"
  exit 0
fi

cd /tmp
wget -qO zellij.tar.gz https://github.com/zellij-org/zellij/releases/latest/download/zellij-x86_64-unknown-linux-musl.tar.gz
tar -xf zellij.tar.gz zellij
install_dir="$HOME/.local/bin"
mkdir -p "$install_dir"
install zellij "$install_dir"
rm zellij.tar.gz zellij

echo "zellij installed to $install_dir"

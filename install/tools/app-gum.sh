#!/usr/bin/env bash
# Install gum — TUI tool used by the dotfiles CLI

set -euo pipefail

if command -v gum >/dev/null 2>&1; then
  echo "gum already installed: $(gum --version)"
  exit 0
fi

cd /tmp
GUM_VERSION="0.17.0"
wget -qO gum.deb "https://github.com/charmbracelet/gum/releases/download/v${GUM_VERSION}/gum_${GUM_VERSION}_amd64.deb"
sudo apt-get install -y --allow-downgrades ./gum.deb
rm gum.deb

echo "gum installed: v${GUM_VERSION}"

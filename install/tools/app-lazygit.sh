#!/usr/bin/env bash
# Install lazygit

set -euo pipefail

if command -v lazygit >/dev/null 2>&1; then
  echo "lazygit already installed: $(lazygit --version | head -1)"
  exit 0
fi

cd /tmp
LAZYGIT_VERSION=$(curl -s https://api.github.com/repos/jesseduffield/lazygit/releases/latest | grep -Po '"tag_name": "v\K[^"]*')
curl -sLo lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/latest/download/lazygit_${LAZYGIT_VERSION}_Linux_x86_64.tar.gz"
tar -xf lazygit.tar.gz lazygit
mkdir -p "$HOME/.local/bin"
install lazygit "$HOME/.local/bin"
rm lazygit.tar.gz lazygit
mkdir -p "$HOME/.config/lazygit"
touch "$HOME/.config/lazygit/config.yml"

echo "lazygit installed: v${LAZYGIT_VERSION}"

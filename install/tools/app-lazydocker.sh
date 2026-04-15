#!/usr/bin/env bash
# Install lazydocker

set -euo pipefail

if command -v lazydocker >/dev/null 2>&1; then
  echo "lazydocker already installed: $(lazydocker --version | head -1)"
  exit 0
fi

cd /tmp
LAZYDOCKER_VERSION=$(curl -s https://api.github.com/repos/jesseduffield/lazydocker/releases/latest | grep -Po '"tag_name": "v\K[^"]*')
curl -sLo lazydocker.tar.gz "https://github.com/jesseduffield/lazydocker/releases/latest/download/lazydocker_${LAZYDOCKER_VERSION}_Linux_x86_64.tar.gz"
tar -xf lazydocker.tar.gz lazydocker
sudo install lazydocker /usr/local/bin
rm lazydocker.tar.gz lazydocker

echo "lazydocker installed: v${LAZYDOCKER_VERSION}"

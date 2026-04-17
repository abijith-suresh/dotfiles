#!/usr/bin/env bash
# Install mise — unified language/runtime version manager

set -euo pipefail

if command -v mise >/dev/null 2>&1; then
  echo "mise already installed: $(mise --version)"
  exit 0
fi

sudo apt update -y
sudo apt install -y gpg wget curl
sudo install -dm 755 /etc/apt/keyrings
wget -qO - https://mise.jdx.dev/gpg-key.pub | gpg --dearmor | sudo tee /etc/apt/keyrings/mise-archive-keyring.gpg >/dev/null
echo "deb [signed-by=/etc/apt/keyrings/mise-archive-keyring.gpg arch=$(dpkg --print-architecture)] https://mise.jdx.dev/deb stable main" | sudo tee /etc/apt/sources.list.d/mise.list >/dev/null
sudo apt update -y
sudo apt install -y mise

echo "mise installed"

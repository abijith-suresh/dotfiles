#!/usr/bin/env bash
# Install GitHub CLI

set -euo pipefail

if command -v gh >/dev/null 2>&1; then
  echo "gh already installed: $(gh --version | head -1)"
  exit 0
fi

if [ ! -f /etc/apt/sources.list.d/github-cli.list ]; then
  [ -f /usr/share/keyrings/githubcli-archive-keyring.gpg ] && sudo rm /usr/share/keyrings/githubcli-archive-keyring.gpg
  curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg status=none
  sudo chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list >/dev/null
fi

sudo apt update -y
sudo apt install -y gh

echo "gh installed"

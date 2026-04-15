#!/bin/bash
# install/terminal/app-zellij.sh
# Install Zellij — modern terminal multiplexer

if command -v zellij &>/dev/null; then
  echo "zellij already installed: $(zellij --version)"
else
  echo "Installing zellij..."
  # Download latest release from GitHub
  zellij_version=$(curl -fsSL https://api.github.com/repos/zellij-org/zellij/releases/latest \
    | grep '"tag_name"' | sed -E 's/.*"v([^"]+)".*/\1/')
  if [ -n "$zellij_version" ]; then
    curl -fsSL "https://github.com/zellij-org/zellij/releases/download/v${zellij_version}/zellij-x86_64-unknown-linux-musl.tar.gz" \
      | tar -xz -C "$HOME/.local/bin" zellij
    echo "zellij $zellij_version installed to ~/.local/bin/zellij"
  else
    echo "Could not fetch latest zellij version. Trying cargo..."
    cargo install zellij 2>/dev/null || echo "Failed to install zellij. Install manually."
  fi
fi

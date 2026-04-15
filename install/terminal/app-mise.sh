#!/bin/bash
# install/terminal/app-mise.sh
# Install mise — unified language/runtime version manager
# Replaces NVM, SDKMAN, pyenv, etc.
# https://mise.jdx.dev/

if command -v mise &>/dev/null; then
  echo "mise already installed: $(mise --version)"
else
  echo "Installing mise..."
  curl -fsSL https://mise.run | sh
  echo "mise installed."
  echo ""
  echo "Add to your shell config (already in .zshrc/.bashrc):"
  echo '  eval "$(mise activate zsh)"  # or bash'
fi

#!/usr/bin/env bash
# Install tmux plugin manager (TPM)

set -euo pipefail

TPM_DIR="$HOME/.tmux/plugins/tpm"
if [ -d "$TPM_DIR" ]; then
  echo "TPM already installed"
  exit 0
fi

git clone https://github.com/tmux-plugins/tpm "$TPM_DIR"

echo "TPM installed"

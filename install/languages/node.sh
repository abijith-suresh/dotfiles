#!/usr/bin/env bash
set -euo pipefail

# shellcheck disable=SC1090,SC1091
source "${DOTFILES_DIR:?}/install/lib.sh"

# Node.js runtime and npm-based language servers used by Neovim.
mise use --global node@lts
mise exec node@lts -- npm install -g \
  bash-language-server \
  pyright \
  typescript \
  typescript-language-server \
  vscode-langservers-extracted \
  yaml-language-server

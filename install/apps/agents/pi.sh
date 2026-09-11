#!/usr/bin/env bash
set -euo pipefail

# shellcheck disable=SC1090,SC1091
source "${DOTFILES_DIR:?}/install/lib.sh"

# Source policy: canonical Pi npm package, checked 2026-09-09.
# https://pi.dev

if command -v pi >/dev/null 2>&1; then
  info "pi already installed"
  exit 0
fi

mise exec node@lts -- npm install -g --ignore-scripts --prefix "$HOME/.local" \
  "@earendil-works/pi-coding-agent"

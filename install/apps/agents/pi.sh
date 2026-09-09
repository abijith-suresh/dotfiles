#!/usr/bin/env bash
set -euo pipefail

# shellcheck disable=SC1090,SC1091
source "${DOTFILES_DIR:?}/install/lib.sh"

# Source policy: canonical Pi npm package, checked 2026-09-09.
# https://pi.dev
PI_VERSION="0.83.0"

if command -v pi >/dev/null 2>&1; then
  info "pi already installed"
else
  mise exec node@lts -- npm install -g --ignore-scripts --prefix "$HOME/.local" \
    "@earendil-works/pi-coding-agent@$PI_VERSION"
fi

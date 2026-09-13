#!/usr/bin/env bash
set -euo pipefail

# shellcheck disable=SC1090,SC1091
source "${DOTFILES_DIR:?}/install/lib.sh"

# Source policy: Pi's official npm installation command, checked 2026-09-13.
# https://pi.dev/docs/latest/quickstart

PI_PACKAGE="@earendil-works/pi-coding-agent"

if command -v pi >/dev/null 2>&1; then
  info "updating Pi"
else
  info "installing Pi"
fi

mise exec node@lts -- npm install -g --ignore-scripts --prefix "$HOME/.local" \
  "$PI_PACKAGE"

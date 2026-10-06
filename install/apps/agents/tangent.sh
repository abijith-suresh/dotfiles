#!/usr/bin/env bash
set -euo pipefail

# shellcheck disable=SC1090,SC1091
source "${DOTFILES_DIR:?}/install/lib.sh"

# Pi's native installer registers packages without replacing other settings.
# Run after Stow so fresh settings already select the theme.
# https://pi.dev/docs/latest/packages
tangent_source="$(mise exec node@lts -- node -p 'require(process.argv[1]).packages[0]' \
  "$DOTFILES_DIR/configs/pi/.pi/agent/settings.json")"
mise exec node@lts -- pi install "$tangent_source"

#!/usr/bin/env bash
set -euo pipefail

# shellcheck disable=SC1090,SC1091
source "${DOTFILES_DIR:?}/install/lib.sh"

# Source policy: Pi's official docs describe the package resource directories
# and user agent directory. Checked 2026-09-09.
# https://pi.dev/docs/latest/extensions
# https://pi.dev/docs/latest/settings
PI_AGENT_DIR="$HOME/.pi/agent"

if [ ! -f "$PI_AGENT_DIR/package-lock.json" ]; then
  info "no managed Pi package found"
  exit 0
fi

info "pi setup dependencies"
mise exec node@lts -- npm ci --ignore-scripts --prefix "$PI_AGENT_DIR"

if [ -f "$PI_AGENT_DIR/extensions/subagents/package-lock.json" ]; then
  mise exec node@lts -- npm ci --ignore-scripts --prefix "$PI_AGENT_DIR/extensions/subagents"
fi

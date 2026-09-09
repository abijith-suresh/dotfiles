#!/usr/bin/env bash
set -euo pipefail

# shellcheck disable=SC1090,SC1091
source "\${DOTFILES_DIR:?}/install/lib.sh"

# Source policy: official Antigravity CLI installer, checked 2026-09-09.
# https://www.antigravity.google/docs/cli/install
if command -v agy >/dev/null 2>&1; then
  info "antigravity already installed"
  exit 0
fi

curl -fsSL https://antigravity.google/cli/install.sh |
  bash -s -- --skip-aliases --skip-path

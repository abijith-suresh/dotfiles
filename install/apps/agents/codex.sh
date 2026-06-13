#!/usr/bin/env bash
set -euo pipefail

# shellcheck disable=SC1090,SC1091
source "${DOTFILES_DIR:?}/install/lib.sh"

# Source policy: official OpenAI Codex standalone installer, checked 2026-06-12.
# https://chatgpt.com/codex/install.sh
if command -v codex >/dev/null 2>&1; then
  info "codex already installed"
  exit 0
fi

case "$PKG_MANAGER" in
  brew)
    pkg_install_cask codex
    ;;
  *)
    curl -fsSL https://chatgpt.com/codex/install.sh | CODEX_NON_INTERACTIVE=1 sh
    ;;
esac

#!/usr/bin/env bash
set -euo pipefail

# shellcheck disable=SC1090,SC1091
source "${DOTFILES_DIR:?}/install/lib.sh"

# Source policy: official OpenCode v2 installation methods.
# https://opencode.ai/v2/docs
#
# v2 installs to ~/.opencode/bin/opencode and also drops an `opencode2`
# compatibility shim. PATH is owned by the zsh package
# (configs/zsh/.config/zsh/.zshrc), so shell rc files must not be modified.
#
# The v2 AUR package is `opencode-beta`; there is no v2 `opencode` package.
# Arch therefore falls through to the official installer instead of installing
# a stale v1 package.

# Detect an existing install so a v1 binary is migrated rather than skipped.
installed=""
if command -v opencode >/dev/null 2>&1; then
  installed="$(opencode --version 2>/dev/null | head -n1 || true)"
fi

major=""
if [[ "$installed" =~ ([0-9]+)\. ]]; then
  major="${BASH_REMATCH[1]}"
fi

if [[ -n "$major" ]] && ((major >= 2)); then
  info "opencode v2 already installed (${installed})"
  exit 0
fi

if [[ -n "$installed" ]]; then
  info "migrating opencode to v2 (found: ${installed})"
fi

case "$PKG_MANAGER" in
  brew)
    brew install anomalyco/tap/opencode-v2
    ;;
  *)
    curl -fsSL https://opencode.ai/v2/install | bash -s -- --no-modify-path
    ;;
esac

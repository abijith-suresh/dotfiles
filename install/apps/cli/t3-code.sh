#!/usr/bin/env bash
set -euo pipefail

# shellcheck disable=SC1090,SC1091
source "${DOTFILES_DIR:?}/install/lib.sh"

# Source policy: official stable, self-contained CLI installer; no Node runtime.
# https://github.com/pingdotgg/t3code/blob/main/docs/user/install.md
# https://t3.codes/install.sh
if command -v t3 >/dev/null 2>&1; then
  info "t3 already installed"
  exit 0
fi

curl -fsSL https://t3.codes/install.sh |
  T3CODE_CHANNEL=stable T3CODE_VERSION='' T3CODE_INSTALL_BIN_DIR="$HOME/.local/bin" sh

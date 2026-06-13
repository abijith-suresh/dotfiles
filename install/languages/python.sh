#!/usr/bin/env bash
set -euo pipefail

# shellcheck disable=SC1090,SC1091
source "${DOTFILES_DIR:?}/install/lib.sh"

mise use --global python@latest
mise exec python@latest -- python -m pip install --upgrade pip ruff

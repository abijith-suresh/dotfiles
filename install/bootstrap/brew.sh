#!/usr/bin/env bash
set -euo pipefail

# shellcheck disable=SC1090,SC1091
source "${DOTFILES_DIR:?}/install/lib.sh"

# Untested macOS bootstrap. Homebrew is the package-manager source of truth.
ensure_homebrew
pkg_update
pkg_install \
  curl \
  git \
  jq \
  make \
  stow \
  unzip \
  wget

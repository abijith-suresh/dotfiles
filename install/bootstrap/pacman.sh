#!/usr/bin/env bash
set -euo pipefail

# shellcheck disable=SC1090,SC1091
source "${DOTFILES_DIR:?}/install/lib.sh"

# Experimental Arch bootstrap.
pkg_update
pkg_install \
  base-devel \
  ca-certificates \
  curl \
  git \
  jq \
  stow \
  unzip \
  wget

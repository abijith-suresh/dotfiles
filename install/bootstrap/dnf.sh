#!/usr/bin/env bash
set -euo pipefail

# shellcheck disable=SC1090,SC1091
source "${DOTFILES_DIR:?}/install/lib.sh"

# Experimental Fedora bootstrap.
pkg_update
pkg_install \
  ca-certificates \
  curl \
  gcc \
  git \
  jq \
  make \
  stow \
  unzip \
  wget

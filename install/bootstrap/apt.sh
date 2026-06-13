#!/usr/bin/env bash
set -euo pipefail

# shellcheck disable=SC1090,SC1091
source "${DOTFILES_DIR:?}/install/lib.sh"

# Base packages for Ubuntu, Debian, and WSL Ubuntu.
pkg_update
pkg_install \
  ca-certificates \
  curl \
  git \
  gnupg \
  jq \
  make \
  stow \
  unzip \
  wget

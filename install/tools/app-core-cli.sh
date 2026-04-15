#!/usr/bin/env bash
# Install core apt-based CLI tools

set -euo pipefail

# shellcheck disable=SC1091
source "$(cd "$(dirname "$0")/.." && pwd)/lib/common.sh"

apt_install_if_missing \
  bat \
  curl \
  eza \
  fastfetch \
  git \
  htop \
  jq \
  neovim \
  ripgrep \
  stow \
  tmux \
  tree \
  unzip \
  wget \
  xclip \
  zip \
  zoxide \
  zsh

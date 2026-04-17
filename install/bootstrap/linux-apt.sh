#!/usr/bin/env bash
# Minimal bootstrap dependencies for Ubuntu/Debian/WSL

set -euo pipefail

# shellcheck disable=SC1091
source "$(cd "$(dirname "$0")/.." && pwd)/lib/common.sh"

sudo apt update -y
apt_install_if_missing \
  ca-certificates \
  curl \
  git \
  jq \
  stow \
  wget

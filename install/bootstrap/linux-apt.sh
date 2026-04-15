#!/usr/bin/env bash
# Minimal bootstrap dependencies for Ubuntu/Debian/WSL

set -euo pipefail

sudo apt update -y
sudo apt install -y \
  ca-certificates \
  curl \
  git \
  jq \
  stow \
  wget

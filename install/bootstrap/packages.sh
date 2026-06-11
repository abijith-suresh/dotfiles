#!/usr/bin/env bash
set -euo pipefail

os="$(uname -s)"
case "$os" in
  Darwin) os="macos" ;;
  Linux)
    if grep -qi microsoft /proc/version 2>/dev/null; then
      os="wsl"
    else
      os="linux"
    fi
    ;;
  *) echo "Unsupported OS: $os"; exit 1 ;;
esac

script_dir="$(cd "$(dirname "$0")" && pwd)"
case "$os" in
  wsl|linux)
    bash "$script_dir/packages/apt.sh"
    ;;
  macos)
    bash "$script_dir/packages/brew.sh"
    ;;
  fedora)
    bash "$script_dir/packages/dnf.sh"
    ;;
  arch)
    bash "$script_dir/packages/pacman.sh"
    ;;
esac

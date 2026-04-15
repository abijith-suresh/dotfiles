#!/usr/bin/env bash
# Shared shell helpers for install/update scripts

set -euo pipefail

command_exists() {
  command -v "$1" >/dev/null 2>&1
}

step() {
  printf "\n==> %s\n" "$*"
}

info() {
  printf "  %s\n" "$*"
}

ok() {
  printf "  ✓ %s\n" "$*"
}

warn() {
  printf "  ! %s\n" "$*"
}

ensure_dir() {
  [ -d "$1" ] || mkdir -p "$1"
}

apt_install_if_missing() {
  local package
  for package in "$@"; do
    if dpkg -s "$package" >/dev/null 2>&1; then
      ok "$package already installed"
    else
      info "Installing $package..."
      sudo apt install -y "$package"
      ok "$package installed"
    fi
  done
}

repo_root() {
  local script_path
  script_path="$(readlink -f "${BASH_SOURCE[0]}")"
  cd "$(dirname "$script_path")/../.." && pwd
}

run_script() {
  local script="$1"
  shift || true

  if [ ! -f "$script" ]; then
    warn "Missing script: $script"
    return 1
  fi

  bash "$script" "$@"
}

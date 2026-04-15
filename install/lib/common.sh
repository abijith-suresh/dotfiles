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

ensure_sudo_access() {
  if [ "$(id -u)" -eq 0 ]; then
    return 0
  fi

  info "Sudo access is required for the next step."
  sudo -v
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

run_task() {
  local title="$1"
  shift

  if command_exists gum; then
    gum spin --spinner dot --title "$title" --show-error -- "$@"
  else
    local log_file status
    log_file="$(mktemp)"
    if "$@" >"$log_file" 2>&1; then
      rm -f "$log_file"
      return 0
    fi

    status=$?
    warn "$title failed"
    cat "$log_file" >&2
    rm -f "$log_file"
    return "$status"
  fi
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

run_named_script() {
  local title="$1"
  local script="$2"
  shift 2 || true

  if [ ! -f "$script" ]; then
    warn "Missing script: $script"
    return 1
  fi

  run_task "$title" bash "$script" "$@"
  ok "$title"
}

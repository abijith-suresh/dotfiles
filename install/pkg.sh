#!/usr/bin/env bash

# Detects OS and package manager (cached across calls)
detect_pkg_manager() {
  if [ -n "${PKG_MANAGER:-}" ]; then
    echo "$PKG_MANAGER"
    return
  fi

  case "$(uname -s)" in
    Darwin)
      PKG_MANAGER="brew"
      ;;
    Linux)
      if grep -qi microsoft /proc/version 2>/dev/null; then
        PKG_MANAGER="apt"
      elif [ -f /etc/os-release ]; then
        . /etc/os-release
        case "$ID" in
          fedora) PKG_MANAGER="dnf" ;;
          arch)   PKG_MANAGER="pacman" ;;
          *)      PKG_MANAGER="apt" ;;
        esac
      else
        PKG_MANAGER="apt"
      fi
      ;;
    *)
      echo "Unsupported OS: $(uname -s)" >&2
      exit 1
      ;;
  esac

  export PKG_MANAGER
  echo "$PKG_MANAGER"
}

pkg_update() {
  local manager
  manager=$(detect_pkg_manager)

  case "$manager" in
    apt)    sudo apt update -y ;;
    brew)   brew update ;;
    dnf)    sudo dnf check-update || true ;;
    pacman) sudo pacman -Sy ;;
  esac
}

pkg_install() {
  local manager
  manager=$(detect_pkg_manager)

  case "$manager" in
    apt)    sudo apt install -y "$@" ;;
    brew)   brew install "$@" ;;
    dnf)    sudo dnf install -y "$@" ;;
    pacman) sudo pacman -S --noconfirm "$@" ;;
  esac
}

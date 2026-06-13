#!/usr/bin/env bash
set -euo pipefail

DOTFILES_REPO="${DOTFILES_REPO:-https://github.com/abijith-suresh/dotfiles.git}"
DOTFILES_REF="${DOTFILES_REF:-main}"
DOTFILES_DIR="${DOTFILES_DIR:-$HOME/.dotfiles}"

has() {
  command -v "$1" >/dev/null 2>&1
}

install_bootstrap_deps() {
  case "$(uname -s)" in
    Darwin)
      if ! has brew; then
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        if [ -x /opt/homebrew/bin/brew ]; then
          eval "$(/opt/homebrew/bin/brew shellenv)"
        elif [ -x /usr/local/bin/brew ]; then
          eval "$(/usr/local/bin/brew shellenv)"
        fi
      fi
      brew update
      brew install git curl
      ;;
    Linux)
      [ -r /etc/os-release ] || {
        echo "Cannot detect Linux distribution: /etc/os-release is missing" >&2
        exit 1
      }
      # shellcheck disable=SC1091
      . /etc/os-release
      case "${ID:-}" in
        ubuntu | debian)
          sudo apt update -y
          sudo apt install -y git curl ca-certificates
          ;;
        fedora)
          sudo dnf install -y git curl ca-certificates
          ;;
        arch)
          sudo pacman -Sy --needed --noconfirm git curl ca-certificates
          ;;
        *)
          echo "Unsupported Linux distribution: ${ID:-unknown}" >&2
          exit 1
          ;;
      esac
      ;;
    *)
      echo "Unsupported OS: $(uname -s)" >&2
      exit 1
      ;;
  esac
}

if ! has git || ! has curl; then
  install_bootstrap_deps
fi

if [ -e "$DOTFILES_DIR" ] && [ ! -d "$DOTFILES_DIR/.git" ]; then
  echo "$DOTFILES_DIR exists but is not a Git checkout. Move it aside and rerun." >&2
  exit 1
fi

if [ ! -d "$DOTFILES_DIR/.git" ]; then
  git clone "$DOTFILES_REPO" "$DOTFILES_DIR"
fi

git -C "$DOTFILES_DIR" fetch origin "$DOTFILES_REF"
git -C "$DOTFILES_DIR" checkout "$DOTFILES_REF"
git -C "$DOTFILES_DIR" pull --ff-only origin "$DOTFILES_REF"

exec "$DOTFILES_DIR/install.sh"

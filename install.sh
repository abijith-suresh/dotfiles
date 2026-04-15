#!/usr/bin/env bash
# Minimal bootstrap entrypoint for a fresh machine

set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALL_DIR="$DOTFILES_DIR/install"

# shellcheck disable=SC1091
source "$INSTALL_DIR/lib/os.sh"
# shellcheck disable=SC1091
source "$INSTALL_DIR/lib/ui.sh"

ui_header

platform="$(detect_os)"
case "$platform" in
  wsl)
    echo "  Platform: WSL Ubuntu"
    ;;
  linux)
    echo "  Platform: Native Ubuntu/Debian"
    ;;
  arch)
    echo "Arch support is not implemented yet."
    exit 1
    ;;
  fedora)
    echo "Fedora support is not implemented yet."
    exit 1
    ;;
  macos)
    echo "macOS support is not implemented yet."
    exit 1
    ;;
  *)
    echo "Unsupported platform."
    exit 1
    ;;
esac

echo ""
if ! ui_confirm "Proceed with bootstrap?"; then
  echo "Aborted."
  exit 0
fi

bash "$INSTALL_DIR/bootstrap/linux-apt.sh"
bash "$INSTALL_DIR/tools/app-gum.sh"

# Hand off to the main CLI install flow.
# Run the script from the repo directly so this works even before stow.
bash "$DOTFILES_DIR/configs/bin/.local/bin/dotfiles" install --profile "$platform"

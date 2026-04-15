#!/usr/bin/env bash
# Minimal bootstrap entrypoint for a fresh machine

set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALL_DIR="$DOTFILES_DIR/install"

# shellcheck disable=SC1091
source "$INSTALL_DIR/lib/common.sh"
# shellcheck disable=SC1091
source "$INSTALL_DIR/lib/os.sh"
# shellcheck disable=SC1091
source "$INSTALL_DIR/lib/ui.sh"

DOTFILES_CLI="$DOTFILES_DIR/configs/bin/.local/bin/dotfiles"

usage() {
  cat <<'EOF'
Usage: ./install.sh

Bootstrap minimal dependencies, make the dotfiles CLI available,
and optionally launch the interactive dotfiles installer.
EOF
}

case "${1:-}" in
  "") ;;
  -h|--help)
    usage
    exit 0
    ;;
  *)
    usage >&2
    exit 1
    ;;
esac

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

step "Bootstrapping this machine"
run_named_script "[1/3] Installing bootstrap dependencies" "$INSTALL_DIR/bootstrap/linux-apt.sh"
run_named_script "[2/3] Installing gum" "$INSTALL_DIR/tools/app-gum.sh"
run_named_script "[3/3] Making dotfiles CLI available" "$INSTALL_DIR/tools/app-bin.sh"

ok "Bootstrap complete"
info "Use 'dotfiles install' for the full setup flow."
info "Use 'dotfiles theme' or 'dotfiles update' later from the CLI."

echo ""
if ui_confirm "Launch the dotfiles installer now?"; then
  bash "$DOTFILES_CLI" install
else
  echo "Next steps:"
  echo "  ~/.local/bin/dotfiles install"
fi

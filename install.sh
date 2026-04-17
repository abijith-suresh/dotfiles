#!/usr/bin/env bash
# Minimal bootstrap entrypoint for a fresh machine

set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALL_DIR="$DOTFILES_DIR/install"

# shellcheck disable=SC1091
source "$INSTALL_DIR/lib/common.sh"
# shellcheck disable=SC1091
source "$INSTALL_DIR/lib/os.sh"
# ui.sh is already sourced transitively through common.sh

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
    printf '%s     Platform detected: %sWSL Ubuntu%s\n\n' \
      "$_UI_MUTED" "$_UI_BLUE" "$_UI_RST"
    ;;
  linux)
    printf '%s     Platform detected: %sNative Ubuntu / Debian%s\n\n' \
      "$_UI_MUTED" "$_UI_BLUE" "$_UI_RST"
    ;;
  arch)
    ui_error "Arch support is not implemented yet."
    exit 1
    ;;
  fedora)
    ui_error "Fedora support is not implemented yet."
    exit 1
    ;;
  macos)
    ui_error "macOS support is not implemented yet."
    exit 1
    ;;
  *)
    ui_error "Unsupported platform."
    exit 1
    ;;
esac

if ! ui_confirm "Proceed with bootstrap?"; then
  ui_info "Aborted."
  exit 0
fi

ensure_sudo_access

ui_section "Bootstrapping"

# Steps 1 and 3 are local/config — use dot spinner
# Step 2 is a download — use globe spinner
export DOTFILES_SPINNER=dot
run_named_script "[1/3] Installing bootstrap dependencies" "$INSTALL_DIR/bootstrap/linux-apt.sh"
export DOTFILES_SPINNER=globe
run_named_script "[2/3] Installing gum" "$INSTALL_DIR/tools/app-gum.sh"
export DOTFILES_SPINNER=dot
run_named_script "[3/3] Making dotfiles CLI available" "$INSTALL_DIR/tools/app-bin.sh"

ui_banner_success "Bootstrap complete" "dotfiles CLI is ready"
ui_info "Use 'dotfiles install' for the full setup flow."
ui_info "Use 'dotfiles theme' or 'dotfiles update' later from the CLI."
echo ""

if ui_confirm "Launch the dotfiles installer now?"; then
  bash "$DOTFILES_CLI" install
else
  ui_info "When ready, run:  ~/.local/bin/dotfiles install"
fi

#!/bin/bash
# install.sh
# Minimal bootstrap — gets the system ready, then hands off to per-tool installers.
# Usage: ./install.sh [--dry-run] [--skip-packages]

set -e

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIGS_DIR="$DOTFILES_DIR/configs"

# --- Flags ---
DRY_RUN=false
SKIP_PACKAGES=false

for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY_RUN=true ;;
    --skip-packages) SKIP_PACKAGES=true ;;
  esac
done

# --- Helpers ---
run() {
  if "$DRY_RUN"; then
    echo "[dry-run] $*"
  else
    "$@"
  fi
}

info() { echo "  $*"; }
step() { echo ""; echo "==> $*"; }

# --- ASCII Art ---
cat << 'HEADER'

  ╭─────────────────────────────────────╮
  │         d o t f i l e s             │
  │     personal config setup           │
  ╰─────────────────────────────────────╯

HEADER

# --- OS Detection ---
detect_os() {
  if grep -qi microsoft /proc/version 2>/dev/null; then
    echo "wsl"
  elif [ -f /etc/os-release ]; then
    local id
    id=$(grep -i "^ID=" /etc/os-release | cut -d= -f2 | tr -d '"')
    local id_like
    id_like=$(grep -i "^ID_LIKE=" /etc/os-release | cut -d= -f2 | tr -d '"')
    case "$id $id_like" in
      *ubuntu* | *debian*) echo "linux" ;;
      *fedora*) echo "fedora" ;;
      *arch*) echo "arch" ;;
      *) echo "unknown" ;;
    esac
  elif [[ "$(uname)" == "Darwin" ]]; then
    echo "macos"
  else
    echo "unknown"
  fi
}

os=$(detect_os)

case "$os" in
  wsl)   info "Platform: WSL Ubuntu" ;;
  linux) info "Platform: Native Ubuntu/Debian" ;;
  macos)
    echo "macOS support coming soon."
    exit 1
    ;;
  fedora)
    echo "Fedora support coming soon."
    exit 1
    ;;
  arch)
    echo "Arch Linux support coming soon."
    exit 1
    ;;
  *)
    echo "Unsupported platform. Exiting."
    exit 1
    ;;
esac

if "$DRY_RUN"; then
  info "Mode: dry-run (no changes will be made)"
fi

echo ""
read -rp "Proceed with setup? [y/N] " confirm
if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
  echo "Aborted."
  exit 0
fi

# --- Step 1: System packages ---
if ! "$SKIP_PACKAGES"; then
  step "Updating system packages"
  run bash "$DOTFILES_DIR/install/linux.sh"
fi

# --- Step 2: Install required tools (gum first for UI) ---
step "Installing required tools"
for installer in "$DOTFILES_DIR/install/terminal/required/"*.sh; do
  [ -f "$installer" ] && run bash "$installer"
done

# --- Step 3: Install CLI tools ---
step "Installing CLI tools"
run bash "$DOTFILES_DIR/install/terminal/apps-cli.sh"

# --- Step 4: Install per-tool configs ---
step "Installing terminal tools"
for installer in "$DOTFILES_DIR/install/terminal/app-"*.sh; do
  [ -f "$installer" ] && run bash "$installer"
done

# --- Step 5: Install coding agents (optional) ---
if command -v gum &>/dev/null; then
  if gum confirm "Install coding agents? (pi, claude, codex, gemini, opencode)"; then
    step "Installing coding agents"
    run bash "$DOTFILES_DIR/install/terminal/agents.sh"
  fi
fi

# --- Step 6: Install programming languages (optional) ---
if command -v gum &>/dev/null && command -v mise &>/dev/null; then
  if gum confirm "Set up programming languages?"; then
    step "Selecting languages"
    run bash "$DOTFILES_DIR/install/terminal/select-language.sh"
  fi
fi

# --- Step 7: Create XDG directories ---
step "Creating XDG directories"
xdg_dirs=(
  "$HOME/.config"
  "$HOME/.local/bin"
  "$HOME/.local/share"
  "$HOME/.local/state"
  "$HOME/.local/state/zsh"
  "$HOME/.cache"
)
for dir in "${xdg_dirs[@]}"; do
  if [ ! -d "$dir" ]; then
    run mkdir -p "$dir"
    ok "Created $dir"
  else
    info "$dir already exists"
  fi
done

# --- Step 8: Stow configs ---
step "Stowing configs"
packages=(zsh git bat starship nvim fzf ripgrep tmux zellij fastfetch btop)
cd "$CONFIGS_DIR"
for pkg in "${packages[@]}"; do
  if [ -d "$pkg" ]; then
    run stow --restow "$pkg" 2>/dev/null && info "Stowed $pkg" || info "Stow $pkg skipped (conflict or missing)"
  else
    info "Package $pkg not found — skipping"
  fi
done
cd "$DOTFILES_DIR"

# --- Step 9: Apply default theme ---
step "Applying default theme (catppuccin)"
run bash "$DOTFILES_DIR/scripts/theme.sh" catppuccin

# --- Summary ---
echo ""
cat << 'FOOTER'

  ╭─────────────────────────────────────╮
  │         Setup complete!             │
  ╰─────────────────────────────────────╯

  Start a new terminal session to load your shell config.
  Run 'nvim' to let lazy.nvim install plugins on first launch.
  Run 'dotfiles theme' to change the color scheme.

FOOTER

#!/bin/bash
# bootstrap.sh
# One-shot setup for dotfiles on WSL Ubuntu or native Ubuntu/Debian Linux.

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
ok()   { echo "  OK: $*"; }

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
      *ubuntu* | *debian*)
        echo "linux"
        ;;
      *fedora*)
        echo "fedora"
        ;;
      *arch*)
        echo "arch"
        ;;
      *)
        echo "unknown"
        ;;
    esac
  elif [[ "$(uname)" == "Darwin" ]]; then
    echo "macos"
  else
    echo "unknown"
  fi
}

os=$(detect_os)

# --- Header ---
echo ""
echo "╔══════════════════════════════════════╗"
echo "║      Dotfiles Bootstrap Script       ║"
echo "╚══════════════════════════════════════╝"
echo ""

case "$os" in
  wsl)   info "Platform: WSL Ubuntu" ;;
  linux) info "Platform: Native Ubuntu/Debian Linux" ;;
  macos)
    echo "macOS support is not yet available."
    echo "See: https://github.com/abijith-suresh/dotfiles/issues"
    exit 1
    ;;
  fedora)
    echo "Fedora support is not yet available."
    echo "See: https://github.com/abijith-suresh/dotfiles/issues"
    exit 1
    ;;
  arch)
    echo "Arch Linux support is not yet available."
    echo "See: https://github.com/abijith-suresh/dotfiles/issues"
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
if "$SKIP_PACKAGES"; then
  info "Mode: --skip-packages (skipping package installation)"
fi

echo ""
read -rp "Proceed with setup? [y/N] " confirm
if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
  echo "Aborted."
  exit 0
fi

# --- Step 1: Install packages ---
if ! "$SKIP_PACKAGES"; then
  step "Installing packages"
  run bash "$DOTFILES_DIR/install/linux.sh"
  ok "Packages installed"
fi

# --- Step 2: Install Zinit ---
step "Installing Zinit"
zinit_dir="${XDG_DATA_HOME:-$HOME/.local/share}/zinit/zinit.git"
if [ -d "$zinit_dir" ]; then
  info "Zinit already installed at $zinit_dir"
else
  run git clone --depth=1 https://github.com/zdharma-continuum/zinit.git "$zinit_dir"
  ok "Zinit installed"
fi

# --- Step 3: Create XDG directories ---
step "Creating XDG directories"
xdg_dirs=(
  "$HOME/.config"
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

# --- Step 4: Stow configs ---
step "Stowing configs"
packages=(zsh git bat starship nvim fzf ripgrep tmux)
cd "$CONFIGS_DIR"
for pkg in "${packages[@]}"; do
  if [ -d "$pkg" ]; then
    run stow --restow "$pkg"
    ok "Stowed $pkg"
  else
    info "Package $pkg not found — skipping"
  fi
done
cd "$DOTFILES_DIR"

# --- Step 5: Set default shell to zsh ---
step "Checking default shell"
if [[ "$SHELL" != "$(which zsh)" ]]; then
  zsh_path="$(which zsh)"
  info "Current shell is $SHELL. Switching to zsh..."
  run chsh -s "$zsh_path"
  echo ""
  echo "  Shell changed. Please log out and back in for the change to take effect."
else
  info "zsh is already the default shell"
fi

# --- Summary ---
echo ""
echo "╔══════════════════════════════════════╗"
echo "║           Setup complete!            ║"
echo "╚══════════════════════════════════════╝"
echo ""
echo "  Start a new terminal session to load your shell config."
echo "  Run 'nvim' to let lazy.nvim install plugins on first launch."
echo ""

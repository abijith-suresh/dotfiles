#!/bin/bash
# install/linux.sh
# Ubuntu/Debian package installer (WSL and native Linux)

set -e

# --- Detect WSL vs native Linux ---
is_wsl() {
  grep -qi microsoft /proc/version 2>/dev/null
}

# --- Package list ---
packages=(
  bat
  btop
  stow
  eza
  fastfetch
  git
  htop
  jq
  neovim
  ripgrep
  tmux
  tree
  unzip
  wget
  xclip
  zip
  zoxide
  zsh
)

echo ""
if is_wsl; then
  echo "Environment: WSL (Ubuntu)"
else
  echo "Environment: Native Linux (Ubuntu/Debian)"
fi
echo ""

# --- Update package list ---
echo "Updating package list..."
sudo apt update -y

# --- Install packages ---
for pkg in "${packages[@]}"; do
  echo ""
  echo "Processing: $pkg"

  if dpkg -s "$pkg" &>/dev/null; then
    echo "  $pkg is already installed. Skipping..."
  else
    echo "  Installing $pkg..."
    sudo apt install -y "$pkg" || {
      echo "  Failed to install $pkg. Skipping..."
      continue
    }
    echo "  $pkg installed."
  fi
done

# --- WSL-specific: fix broken Docker vendor completions ---
if is_wsl; then
  echo ""
  echo "WSL detected — cleaning up broken Docker vendor completions if present..."
  sudo rm -f /usr/share/zsh/vendor-completions/_docker
  rm -f "$HOME"/.zcompdump*
  echo "  Done. Docker completions will be loaded via Zinit instead."
fi

# --- Upgrade installed packages ---
echo ""
echo "Running full upgrade..."
sudo apt upgrade -y

echo ""
echo "Installing catppuccin theme for Vim..."
if [ ! -d "$HOME/.vim/pack/vendor/start/catppuccin" ]; then
  mkdir -p ~/.vim/pack/vendor/start
  git clone https://github.com/catppuccin/vim.git ~/.vim/pack/vendor/start/catppuccin
  echo "  catppuccin/vim installed."
else
  echo "  catppuccin/vim already installed."
fi

echo ""
echo "Installing Tmux Plugin Manager (TPM)..."
if [ ! -d "$HOME/.tmux/plugins/tpm" ]; then
  git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
  echo "  TPM installed."
  echo "  Note: Press 'Prefix + I' in tmux to install plugins."
else
  echo "  TPM already installed."
fi

echo ""
echo "Installing SDKMAN (Java version manager)..."

if [ -d "$HOME/.sdkman" ]; then
  echo "  SDKMAN already installed."
else
  echo "  Installing SDKMAN..."
  curl -s "https://get.sdkman.io?rcupdate=false" | bash
  echo "  SDKMAN installed."
fi

export SDKMAN_DIR="$HOME/.sdkman"
[[ -s "$SDKMAN_DIR/bin/sdkman-init.sh" ]] && source "$SDKMAN_DIR/bin/sdkman-init.sh"

echo ""
echo "Checking Java installation..."

if [ -d "$HOME/.sdkman/candidates/java/21.0.6-tem" ]; then
  echo "  Java 21.0.6-tem already installed."
else
  echo "  Installing Java 21.0.6-tem (Eclipse Temurin)..."
  sdk install java 21.0.6-tem
  echo "  Java 21.0.6-tem installed."
fi

sdk default java 21.0.6-tem
echo "  Java 21.0.6-tem set as default."

echo ""
echo "All done!"

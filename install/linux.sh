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
  fzf
  git
  htop
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
echo "All done!"

#!/bin/bash
# install/terminal/apps-cli.sh
# Install core CLI tools via apt

packages=(
  bat
  btop
  curl
  eza
  fastfetch
  fzf
  git
  htop
  jq
  neovim
  ripgrep
  stow
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
echo "Installing CLI tools..."

for pkg in "${packages[@]}"; do
  if dpkg -s "$pkg" &>/dev/null 2>&1; then
    echo "  ✓ $pkg"
  else
    echo "  Installing $pkg..."
    sudo apt install -y "$pkg" || {
      echo "  Failed to install $pkg. Skipping..."
      continue
    }
  fi
done

echo "CLI tools installed."

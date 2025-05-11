#!/bin/bash

# Exit on critical error
set -e

# List of manually installed packages
packages=(
    bat
    btop
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
    zip
    zoxide
    zsh
)

# Update package list first
echo -e "\nUpdating package list..."
sudo apt update -y

for pkg in "${packages[@]}"; do
    echo -e "\nProcessing package: $pkg"

    if dpkg -s "$pkg" &>/dev/null; then
        echo " $pkg is already installed. Skipping..."
    else
        echo "$pkg is not installed. Installing..."
        sudo apt install -y "$pkg" || {
            echo " Failed to install $pkg. Skipping..."
            continue
        }
        echo "$pkg installed successfully."
    fi
done

# Upgrade all upgradable packages (including manually installed ones)
echo -e "\nRunning full upgrade for all installed packages..."
sudo apt upgrade -y

echo -e "\nAll done!"

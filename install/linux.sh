#!/bin/bash
# install/linux.sh
# Base system setup for Ubuntu/Debian (WSL and native Linux)
# Handles apt update/upgrade. Tool installation is done by per-tool scripts.

set -e
set -o pipefail

# --- Detect environment ---
is_wsl() {
  grep -qi microsoft /proc/version 2>/dev/null
}

echo ""
if is_wsl; then
  echo "Environment: WSL (Ubuntu)"
else
  echo "Environment: Native Linux (Ubuntu/Debian)"
fi

# --- Update package list ---
echo "Updating package list..."
sudo apt update -y

# --- Upgrade installed packages ---
echo "Running full upgrade..."
sudo apt upgrade -y

# --- WSL-specific: fix broken Docker vendor completions ---
if is_wsl; then
  echo "WSL detected — cleaning up broken Docker vendor completions if present..."
  sudo rm -f /usr/share/zsh/vendor-completions/_docker
  rm -f "$HOME"/.zcompdump*
  echo "  Done."
fi

echo ""
echo "System packages updated."

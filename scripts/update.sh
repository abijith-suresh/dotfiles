#!/usr/bin/env bash
set -e

echo "Starting system update for dotfiles (Ubuntu WSL + zinit)..."

# --- Detect OS ---
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    if grep -qi microsoft /proc/version; then
        echo "Detected Ubuntu on WSL"

        echo "Updating APT packages..."
        sudo apt update && sudo apt upgrade -y && sudo apt autoremove -y
    else
        if [ -f /etc/os-release ]; then
            . /etc/os-release
            case "$ID" in
                arch)
                    echo "Arch support coming soon."
                    # sudo pacman -Syu --noconfirm
                    ;;
                ubuntu)
                    echo "Native Ubuntu support (non-WSL) coming soon."
                    # sudo apt update && sudo apt upgrade -y
                    ;;
                *)
                    echo "Unsupported Linux distro: $ID"
                    ;;
            esac
        fi
    fi
elif [[ "$OSTYPE" == "darwin"* ]]; then
    echo "macOS support coming soon."
    # brew update && brew upgrade && brew cleanup
else
    echo "Unsupported OS: $OSTYPE"
fi

# --- Zinit plugin update ---
if [[ -n "$ZDOTDIR" ]]; then
    ZSH_CONFIG_DIR="$ZDOTDIR"
else
    ZSH_CONFIG_DIR="$HOME"
fi

if [[ -f "$ZSH_CONFIG_DIR/.zshrc" ]] && grep -q "zinit" "$ZSH_CONFIG_DIR/.zshrc"; then
    echo "Updating Zinit plugins..."
    zsh -i -c "zinit self-update; zinit update --all"
else
    echo "Zinit not detected in .zshrc, skipping plugin update."
fi

echo "Done. Ubuntu WSL system and Zinit plugins updated!"

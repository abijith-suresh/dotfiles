#!/bin/bash
# install/terminal/app-zsh.sh
# Set zsh as default shell and install Zinit plugin manager

# --- Set default shell ---
if [[ "$SHELL" != "$(which zsh 2>/dev/null)" ]]; then
  zsh_path="$(which zsh)"
  if [ -n "$zsh_path" ]; then
    echo "Switching default shell to zsh..."
    chsh -s "$zsh_path"
    echo "Shell changed. Log out and back in for the change to take effect."
  else
    echo "zsh not found. Install it first."
  fi
else
  echo "zsh is already the default shell."
fi

# --- Install Zinit ---
zinit_dir="${XDG_DATA_HOME:-$HOME/.local/share}/zinit/zinit.git"
if [ -d "$zinit_dir" ]; then
  echo "Zinit already installed at $zinit_dir"
else
  echo "Installing Zinit..."
  git clone --depth=1 https://github.com/zdharma-continuum/zinit.git "$zinit_dir"
  echo "Zinit installed."
fi

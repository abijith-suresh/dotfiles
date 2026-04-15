#!/bin/bash
# install/terminal/app-tmux.sh
# Install Tmux Plugin Manager (TPM)

tpm_dir="$HOME/.tmux/plugins/tpm"
if [ -d "$tpm_dir" ]; then
  echo "TPM already installed."
else
  echo "Installing TPM..."
  git clone https://github.com/tmux-plugins/tpm "$tpm_dir"
  echo "TPM installed. Press 'Prefix + I' in tmux to install plugins."
fi

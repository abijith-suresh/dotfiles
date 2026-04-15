#!/bin/bash
# install/terminal/app-fzf.sh
# Install latest fzf from GitHub (apt ships outdated version)

fzf_latest=$(curl -fsSL https://api.github.com/repos/junegunn/fzf/releases/latest \
  | python3 -c "import sys,json; print(json.load(sys.stdin)['tag_name'].lstrip('v'))" 2>/dev/null)

if [ -z "$fzf_latest" ]; then
  echo "Could not fetch latest fzf version — skipping (will use apt version)"
  return 0
fi

fzf_installed=$(fzf --version 2>/dev/null | cut -d' ' -f1)
if [ "$fzf_installed" = "$fzf_latest" ]; then
  echo "fzf $fzf_latest already installed."
else
  echo "Installing fzf $fzf_latest..."
  mkdir -p "$HOME/.local/bin"
  curl -fsSL "https://github.com/junegunn/fzf/releases/download/v${fzf_latest}/fzf-${fzf_latest}-linux_amd64.tar.gz" \
    | tar -xz -C "$HOME/.local/bin" fzf
  echo "fzf $fzf_latest installed to ~/.local/bin/fzf"
fi

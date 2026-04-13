#!/bin/bash
# install/linux.sh
# Ubuntu/Debian package installer (WSL and native Linux)

set -e
set -o pipefail

# --- Detect WSL vs native Linux ---
is_wsl() {
  grep -qi microsoft /proc/version 2>/dev/null
}

# --- NVM and Node.js ---
install_nvm() {
  export NVM_DIR="$HOME/.nvm"

  if [ -s "$NVM_DIR/nvm.sh" ]; then
    echo "  NVM already installed."
  else
    echo "  Installing NVM..."
    curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.4/install.sh \
      | PROFILE=/dev/null NVM_DIR="$NVM_DIR" bash
    echo "  NVM installed."
  fi

  if [ -s "$NVM_DIR/nvm.sh" ]; then
    # shellcheck disable=SC1090
    . "$NVM_DIR/nvm.sh"
    [ -s "$NVM_DIR/bash_completion" ] && . "$NVM_DIR/bash_completion"
  else
    echo "  Failed to load NVM after installation."
    exit 1
  fi
}

install_node_lts() {
  local node_lts_version
  node_lts_version="$(nvm version --lts 2>/dev/null || true)"

  if [ -n "$node_lts_version" ] && [ "$node_lts_version" != "N/A" ]; then
    echo "  Node.js LTS already installed: $node_lts_version"
  else
    echo "  Installing latest Node.js LTS..."
    nvm install --lts
    echo "  Node.js LTS installed."
  fi

  echo "  Setting default Node.js to LTS..."
  nvm alias default 'lts/*' >/dev/null
  nvm use --lts >/dev/null
  echo "  Using Node.js $(node --version) and npm $(npm --version)."
}

# --- Package list ---
packages=(
  bat
  btop
  cloc
  curl
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
echo "Installing NVM..."
install_nvm

echo ""
echo "Installing Node.js LTS..."
install_node_lts

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

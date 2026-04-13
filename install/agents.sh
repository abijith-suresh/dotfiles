#!/usr/bin/env bash
# install/agents.sh
# Install supported coding agent CLIs for Linux/WSL.

set -e
set -o pipefail

command_exists() {
  command -v "$1" &>/dev/null
}

load_nvm() {
  export NVM_DIR="$HOME/.nvm"

  if [ -s "$NVM_DIR/nvm.sh" ]; then
    # shellcheck disable=SC1090
    . "$NVM_DIR/nvm.sh"
    [ -s "$NVM_DIR/bash_completion" ] && . "$NVM_DIR/bash_completion"
    return 0
  fi

  return 1
}

install_npm_agent() {
  local command_name="$1"
  local package_name="$2"
  local display_name="$3"

  if command_exists "$command_name"; then
    echo "  $display_name is already installed. Skipping..."
    return 0
  fi

  echo "  Installing $display_name..."
  if npm install -g "$package_name"; then
    echo "  $display_name installed."
  else
    echo "  Failed to install $display_name. Skipping..."
  fi
}

install_claude() {
  if command_exists claude; then
    echo "  claude is already installed. Skipping..."
    return 0
  fi

  echo "  Installing claude..."
  if curl -fsSL https://claude.ai/install.sh | bash; then
    echo "  claude installed."
  else
    echo "  Failed to install claude. Skipping..."
  fi
}

install_copilot() {
  if command_exists copilot; then
    echo "  copilot is already installed. Skipping..."
    return 0
  fi

  echo "  Installing copilot..."
  if curl -fsSL https://gh.io/copilot-install | PREFIX="$HOME/.local" bash; then
    echo "  copilot installed."
  else
    echo "  Failed to install copilot. Skipping..."
  fi
}

install_opencode() {
  if command_exists opencode; then
    echo "  opencode is already installed. Skipping..."
    return 0
  fi

  echo "  Installing opencode..."
  if curl -fsSL https://opencode.ai/install | bash -s -- --no-modify-path; then
    export PATH="$HOME/.opencode/bin:$PATH"
    echo "  opencode installed."
  else
    echo "  Failed to install opencode. Skipping..."
  fi
}

install_npm_agents() {
  echo ""
  echo "Installing npm-based coding agents..."

  if ! load_nvm; then
    echo "  NVM was not found at $HOME/.nvm. Continuing with current node/npm if available..."
  fi

  if ! command_exists node || ! command_exists npm; then
    echo "  node/npm are not available. Skipping npm-based agents..."
    return 0
  fi

  install_npm_agent pi @mariozechner/pi-coding-agent "pi"
  install_npm_agent codex @openai/codex "codex"
  install_npm_agent gemini @google/gemini-cli "gemini"
}

install_curl_agents() {
  echo ""
  echo "Installing curl-based coding agents..."

  if ! command_exists curl; then
    echo "  curl is not installed. Skipping curl-based agents..."
    return 0
  fi

  install_claude
  install_copilot
  install_opencode
}

main() {
  export PATH="$HOME/.local/bin:$HOME/.opencode/bin:$PATH"

  echo ""
  echo "╔══════════════════════════════════════╗"
  echo "║      Coding Agents Installer         ║"
  echo "╚══════════════════════════════════════╝"

  install_npm_agents
  install_curl_agents

  echo ""
  echo "All done!"
  echo ""
  echo "Authentication/setup reminders:"
  echo "  - pi: run 'pi' and use /login or configure an API key"
  echo "  - claude: run 'claude' and follow the browser prompt"
  echo "  - copilot: run 'copilot' and use /login if needed"
  echo "  - gemini: run 'gemini' and sign in or set GEMINI_API_KEY"
  echo "  - codex: run 'codex' and sign in or set OPENAI_API_KEY"
  echo "  - opencode: run 'opencode' and use /connect or provider API keys"
}

main "$@"

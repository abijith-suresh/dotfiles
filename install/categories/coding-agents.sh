#!/usr/bin/env bash
# Install all supported coding agents

set -euo pipefail

install_dir="$(cd "$(dirname "$0")/.." && pwd)"

# shellcheck disable=SC1091
source "$install_dir/lib/common.sh"

step "Installing coding agents"

failed=()
install_agent() {
  local title="$1"
  local script="$2"
  local name="$3"

  if ! run_named_script "$title" "$script"; then
    failed+=("$name")
  fi
}

install_agent "[1/6] Installing pi" "$install_dir/agents/app-pi.sh" pi
install_agent "[2/6] Installing codex" "$install_dir/agents/app-codex.sh" codex
install_agent "[3/6] Installing gemini" "$install_dir/agents/app-gemini.sh" gemini
install_agent "[4/6] Installing claude" "$install_dir/agents/app-claude.sh" claude
install_agent "[5/6] Installing copilot" "$install_dir/agents/app-copilot.sh" copilot
install_agent "[6/6] Installing opencode" "$install_dir/agents/app-opencode.sh" opencode

if [ "${#failed[@]}" -gt 0 ]; then
  echo ""
  warn "Some coding agent installs failed: ${failed[*]}"
fi

echo ""
echo "Authentication/setup reminders:"
echo "  - pi: run 'pi' and use /login or configure an API key"
echo "  - claude: run 'claude' and follow the browser prompt"
echo "  - copilot: run 'copilot' and use /login if needed"
echo "  - gemini: run 'gemini' and sign in or set GEMINI_API_KEY"
echo "  - codex: run 'codex' and sign in or set OPENAI_API_KEY"
echo "  - opencode: run 'opencode' and use /connect or provider API keys"

#!/usr/bin/env bash
# Install all supported coding agents

set -euo pipefail

install_dir="$(cd "$(dirname "$0")/.." && pwd)"

# shellcheck disable=SC1091
source "$install_dir/lib/common.sh"

step "Installing coding agents"
run_named_script "[1/6] Installing pi" "$install_dir/agents/app-pi.sh"
run_named_script "[2/6] Installing codex" "$install_dir/agents/app-codex.sh"
run_named_script "[3/6] Installing gemini" "$install_dir/agents/app-gemini.sh"
run_named_script "[4/6] Installing claude" "$install_dir/agents/app-claude.sh"
run_named_script "[5/6] Installing copilot" "$install_dir/agents/app-copilot.sh"
run_named_script "[6/6] Installing opencode" "$install_dir/agents/app-opencode.sh"

echo ""
echo "Authentication/setup reminders:"
echo "  - pi: run 'pi' and use /login or configure an API key"
echo "  - claude: run 'claude' and follow the browser prompt"
echo "  - copilot: run 'copilot' and use /login if needed"
echo "  - gemini: run 'gemini' and sign in or set GEMINI_API_KEY"
echo "  - codex: run 'codex' and sign in or set OPENAI_API_KEY"
echo "  - opencode: run 'opencode' and use /connect or provider API keys"

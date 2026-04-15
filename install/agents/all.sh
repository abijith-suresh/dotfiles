#!/usr/bin/env bash
set -euo pipefail

base_dir="$(cd "$(dirname "$0")" && pwd)"

for script in \
  "$base_dir/app-pi.sh" \
  "$base_dir/app-codex.sh" \
  "$base_dir/app-gemini.sh" \
  "$base_dir/app-claude.sh" \
  "$base_dir/app-copilot.sh" \
  "$base_dir/app-opencode.sh"; do
  bash "$script"
done

echo ""
echo "Authentication/setup reminders:"
echo "  - pi: run 'pi' and use /login or configure an API key"
echo "  - claude: run 'claude' and follow the browser prompt"
echo "  - copilot: run 'copilot' and use /login if needed"
echo "  - gemini: run 'gemini' and sign in or set GEMINI_API_KEY"
echo "  - codex: run 'codex' and sign in or set OPENAI_API_KEY"
echo "  - opencode: run 'opencode' and use /connect or provider API keys"

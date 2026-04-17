#!/usr/bin/env bash
# Install all supported coding agents

set -euo pipefail

install_dir="$(cd "$(dirname "$0")/.." && pwd)"

# shellcheck disable=SC1091
source "$install_dir/lib/common.sh"

ui_section "Installing coding agents"

failed=()
install_agent() {
  local title="$1"
  local script="$2"
  local name="$3"

  if ! run_named_script "$title" "$script"; then
    failed+=("$name")
  fi
}

export DOTFILES_SPINNER=globe
install_agent "[1/6] Installing pi"       "$install_dir/agents/app-pi.sh"       pi
install_agent "[2/6] Installing codex"    "$install_dir/agents/app-codex.sh"    codex
install_agent "[3/6] Installing gemini"   "$install_dir/agents/app-gemini.sh"   gemini
install_agent "[4/6] Installing claude"   "$install_dir/agents/app-claude.sh"   claude
install_agent "[5/6] Installing copilot"  "$install_dir/agents/app-copilot.sh"  copilot
install_agent "[6/6] Installing opencode" "$install_dir/agents/app-opencode.sh" opencode

if [ "${#failed[@]}" -gt 0 ]; then
  echo ""
  ui_warn "Some coding agent installs failed: ${failed[*]}"
fi

# ── Setup reminder panel ──────────────────────────────────────────────────────

echo ""
if command -v gum >/dev/null 2>&1; then
  # Build the reminder text
  heading="$(gum style --foreground "$UI_BLUE" --bold "  Agent Setup Reminders")"
  divider="$(gum style --foreground "$UI_BORDER" "  ──────────────────────────────────────────")"

  _agent_line() {
    local name="$1" hint="$2"
    printf '%s%-12s%s %s%s%s\n' \
      "$_UI_ACCENT" "$name" "$_UI_RST" \
      "$_UI_MUTED"  "$hint" "$_UI_RST"
  }

  reminders="$(
    _agent_line "pi"       "run 'pi'       → /login or configure an API key"
    _agent_line "claude"   "run 'claude'   → follow the browser prompt"
    _agent_line "copilot"  "run 'copilot'  → /login if needed"
    _agent_line "gemini"   "run 'gemini'   → sign in or set GEMINI_API_KEY"
    _agent_line "codex"    "run 'codex'    → sign in or set OPENAI_API_KEY"
    _agent_line "opencode" "run 'opencode' → /connect or set provider API keys"
  )"

  gum style \
    --border rounded \
    --border-foreground "$UI_BLUE" \
    --padding "0 2" \
    "$heading" \
    "" \
    "$divider" \
    "" \
    "$reminders"
else
  printf '\nAuthentication/setup reminders:\n'
  printf '  pi       · run '"'"'pi'"'"' and use /login or configure an API key\n'
  printf '  claude   · run '"'"'claude'"'"' and follow the browser prompt\n'
  printf '  copilot  · run '"'"'copilot'"'"' and use /login if needed\n'
  printf '  gemini   · run '"'"'gemini'"'"' and sign in or set GEMINI_API_KEY\n'
  printf '  codex    · run '"'"'codex'"'"' and sign in or set OPENAI_API_KEY\n'
  printf '  opencode · run '"'"'opencode'"'"' and use /connect or set provider API keys\n'
fi
echo ""

#!/bin/bash
# setup-agents.sh
# Wire per-tool skills/ directories to the shared ~/.agents/skills/ source.
#
# Replaces any existing per-skill symlinks (or real dirs) with a single
# directory symlink per tool, so all tools automatically pick up new skills.

set -e

AGENTS_SKILLS="$HOME/.agents/skills"

info() { echo "  $*"; }
ok()   { echo "  OK: $*"; }

# --- Tool skills directories ---
declare -A TOOL_SKILLS=(
  ["claude"]="$HOME/.claude/skills"
  ["gemini"]="$HOME/.gemini/skills"
  ["copilot"]="$HOME/.copilot/skills"
  ["opencode"]="$HOME/.config/opencode/skills"
)

for tool in "${!TOOL_SKILLS[@]}"; do
  target="${TOOL_SKILLS[$tool]}"
  parent="$(dirname "$target")"

  # Remove existing symlink or directory
  if [ -L "$target" ]; then
    rm "$target"
    info "Removed existing symlink: $target"
  elif [ -d "$target" ]; then
    rm -rf "$target"
    info "Removed existing directory: $target"
  fi

  # Ensure parent directory exists
  mkdir -p "$parent"

  # Create single directory symlink → shared skills source
  ln -s "$AGENTS_SKILLS" "$target"
  ok "$tool: $target -> $AGENTS_SKILLS"
done

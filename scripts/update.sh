#!/usr/bin/env bash
# scripts/update.sh — Update system and tools
# Can be run directly or via 'dotfiles update'

set -e

DOTFILES_DIR="$(cd "$(dirname "$0")/.." && pwd)"

# Delegate to the dotfiles CLI
bash "$DOTFILES_DIR/configs/bin/.local/bin/dotfiles" update

#!/usr/bin/env bash
set -euo pipefail

# shellcheck disable=SC1090,SC1091
source "${DOTFILES_DIR:?}/install/lib.sh"

# Source policy: official OpenCode v2 installation methods.
# https://opencode.ai/v2/docs
#
# v2 installs to ~/.opencode/bin/opencode and also drops an `opencode2`
# compatibility shim. PATH is owned by the zsh package
# (configs/zsh/.config/zsh/.zshrc), so shell rc files must not be modified.
#
# The v2 AUR package is `opencode-beta`; there is no v2 `opencode` package.
# Arch therefore falls through to the official installer instead of installing
# a stale v1 package.

# Detect an existing install so a v1 binary is migrated rather than skipped.
# The v2 native location is ~/.opencode/bin/opencode; it is not on the
# installer shell's PATH (the zsh package owns interactive PATH), so the
# installer shell must check the native path and expose the binary through
# ~/.local/bin for scripts and end-state verification.
native_bin="$HOME/.opencode/bin/opencode"
installed=""
if [ -x "$native_bin" ]; then
  installed="$("$native_bin" --version 2>/dev/null | head -n1 || true)"
elif command -v opencode >/dev/null 2>&1; then
  installed="$(opencode --version 2>/dev/null | head -n1 || true)"
fi

major=""
if [[ "$installed" =~ ([0-9]+)\. ]]; then
  major="${BASH_REMATCH[1]}"
fi

if [[ -n "$major" ]] && ((major >= 2)); then
  info "opencode v2 already installed (${installed})"
  if [ -x "$native_bin" ] && [ ! -e "$HOME/.local/bin/opencode" ]; then
    mkdir -p "$HOME/.local/bin"
    ln -sfn "$native_bin" "$HOME/.local/bin/opencode"
    info "opencode exposed at ~/.local/bin/opencode"
  fi
  exit 0
fi

if [[ -n "$installed" ]]; then
  info "migrating opencode to v2 (found: ${installed})"
fi

case "$PKG_MANAGER" in
  brew)
    brew install anomalyco/tap/opencode-v2
    ;;
  *)
    curl -fsSL https://opencode.ai/v2/install | bash -s -- --no-modify-path
    ;;
esac

# Expose the v2 native binary on the installer PATH; repeat runs also
# refresh a stale link.
if [ -x "$native_bin" ]; then
  mkdir -p "$HOME/.local/bin"
  ln -sfn "$native_bin" "$HOME/.local/bin/opencode"
  info "opencode exposed at ~/.local/bin/opencode"
fi

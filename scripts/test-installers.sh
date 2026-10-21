#!/usr/bin/env bash
# Sandbox-run agent installers in a throwaway HOME. Needs network; each app
# runs its real upstream installer. Verifies the three things static checks
# cannot: the install succeeds, a binary lands in ~/.local/bin, and no shell
# rc file in $HOME gets touched. Usage: test-installers.sh [app ...]
# (default: every agent installer that can run without mise).
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# These installers drive mise/node and assume a provisioned toolchain;
# run them explicitly once mise exists.
MISE_DEPENDENT=(pi tangent)

apps=("$@")
if [ "${#apps[@]}" -eq 0 ]; then
  mapfile -t apps < <(
    for script in "$REPO_DIR"/install/apps/agents/*.sh; do
      name="$(basename "$script" .sh)"
      for skip in "${MISE_DEPENDENT[@]}"; do
        [ "$name" = "$skip" ] && continue 2
      done
      printf '%s\n' "$name"
    done
  )
fi

status=0
for app in "${apps[@]}"; do
  script="$REPO_DIR/install/apps/agents/$app.sh"
  if [ ! -f "$script" ]; then
    printf '==> %s\n  no installer script\n' "$app" >&2
    status=1
    continue
  fi

  sandbox="$(mktemp -d /tmp/dotfiles-installer.XXXXXX)"
  home="$sandbox/home"
  log="$sandbox/install.log"
  mkdir -p "$home"
  printf '==> %s\n' "$app"

  # A clean PATH keeps host binaries (e.g. an already-installed agy) from
  # making the sandboxed install a no-op.
  if PATH=/usr/bin:/bin HOME="$home" SHELL='' DOTFILES_DIR="$REPO_DIR" PLATFORM=ubuntu PKG_MANAGER=apt \
    bash "$script" >"$log" 2>&1; then
    :
  else
    printf '  install failed (log: %s)\n' "$log" >&2
    status=1
    continue
  fi

  rc_ok=1
  for rc in .zshrc .zshenv .profile .bashrc .bash_profile; do
    if [ -e "$home/$rc" ]; then
      printf '  rc file touched: %s\n' "$rc" >&2
      rc_ok=0
    fi
  done

  bin_ok=0
  for entry in "$home"/.local/bin/*; do
    if [ -x "$entry" ]; then
      bin_ok=1
      printf '  binary: %s\n' "${entry##*/}"
    fi
  done
  if [ "$bin_ok" -eq 0 ]; then
    printf '  no binary installed into ~/.local/bin\n' >&2
  fi

  if [ "$rc_ok" -eq 0 ] || [ "$bin_ok" -eq 0 ]; then
    status=1
  fi
  rm -rf -- "$sandbox"
done

exit "$status"

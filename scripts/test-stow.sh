#!/usr/bin/env bash
# Zsh snippets below expand variables inside the temporary shell.
# shellcheck disable=SC2016
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
test_root="$(mktemp -d /tmp/dotfiles-stow-test.XXXXXX)"
trap 'rm -rf -- "$test_root"' EXIT

run_stow() {
  local target_home="$1"
  HOME="$target_home" \
    DOTFILES_DIR="$REPO_DIR" \
    PLATFORM=ubuntu \
    PKG_MANAGER=apt \
    bash "$REPO_DIR/install/stow.sh"
}

assert_link() {
  local target="$1" source="$2"
  [ -L "$target" ]
  [ "$(readlink -f "$target")" = "$source" ]
}

assert_no_backups() {
  if find "$1" -name '*.backup*' -print -quit | grep -q .; then
    printf '%s\n' 'unexpected backup after repeated Stow run' >&2
    exit 1
  fi
}

# Fresh configs are direct Stow links, including on repeat runs.
clean_home="$test_root/clean"
mkdir -p "$clean_home"
run_stow "$clean_home" >/dev/null
run_stow "$clean_home" >/dev/null
assert_link "$clean_home/.zshenv" "$REPO_DIR/configs/zsh/.zshenv"
assert_link "$clean_home/.config/git/config" "$REPO_DIR/configs/git/.config/git/config"
assert_no_backups "$clean_home"

# An existing unmanaged file is backed up and the package deploys over it.
conflict_home="$test_root/conflict"
mkdir -p "$conflict_home"
printf '%s\n' 'original-zshenv' >"$conflict_home/.zshenv"
run_stow "$conflict_home" >/dev/null
run_stow "$conflict_home" >/dev/null
grep -qx 'original-zshenv' "$conflict_home/.zshenv.backup"
assert_link "$conflict_home/.zshenv" "$REPO_DIR/configs/zsh/.zshenv"
[ "$(find "$conflict_home" -name '*.backup*' | wc -l)" -eq 1 ]

# Both initial and inherited ZDOTDIR startup load the shared environment.
env -u GOCACHE HOME="$clean_home" ZDOTDIR="$clean_home" zsh -c '
  set -e
  [[ "$ZDOTDIR" == "$HOME/.config/zsh" ]]
  [[ "$XDG_CONFIG_HOME" == "$HOME/.config" ]]
  [[ "$GOCACHE" == "$HOME/.cache/go-build" ]]
  zsh -c "[[ \${XDG_STATE_HOME} == \${HOME}/.local/state ]]"
'

# Installer additions in a regular home rc load once, even if it sources the
# XDG rc. A same-file hard link and a home symlink must both be skipped.
cat >"$clean_home/.zshrc" <<'ZSH'
(( HOME_RC_READS += 1 ))
source "$ZDOTDIR/.zshrc"
export INSTALLER_ADDITION=loaded
ZSH
env -i HOME="$clean_home" PATH=/usr/bin:/bin TERM=dumb zsh -ic '
  [[ "$HOME_RC_READS" == 1 && "$INSTALLER_ADDITION" == loaded ]]
' >/dev/null
[ ! -L "$clean_home/.zshrc" ]
rm "$clean_home/.zshrc"
ln "$REPO_DIR/configs/zsh/.config/zsh/.zshrc" "$clean_home/.zshrc"
env -i HOME="$clean_home" PATH=/usr/bin:/bin TERM=dumb zsh -ic '
  [[ -z ${_DOTFILES_ZSHRC_LOADING:-} ]]
' >/dev/null
rm "$clean_home/.zshrc"
ln -s "$REPO_DIR/configs/zsh/.config/zsh/.zshrc" "$clean_home/.zshrc"
env -i HOME="$clean_home" PATH=/usr/bin:/bin TERM=dumb zsh -ic '
  [[ -z ${_DOTFILES_ZSHRC_LOADING:-} ]]
' >/dev/null

printf '%s\n' 'Stow deployment, conflict backup, zsh startup, and repeatability passed.'

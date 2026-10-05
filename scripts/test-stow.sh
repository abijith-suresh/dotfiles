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

# Fresh settings and configs are direct Stow links, including on repeat runs.
clean_home="$test_root/clean"
mkdir -p "$clean_home"
run_stow "$clean_home" >/dev/null
run_stow "$clean_home" >/dev/null
assert_link "$clean_home/.zshenv" "$REPO_DIR/configs/zsh/.zshenv"
assert_link "$clean_home/.pi/agent/settings.json" "$REPO_DIR/configs/pi/.pi/agent/settings.json"
assert_link "$clean_home/.codex/config.toml" "$REPO_DIR/configs/codex/.codex/config.toml"
assert_no_backups "$clean_home"

# A CLI may replace a settings link. Rerunning must keep its owned state active.
rm "$clean_home/.codex/config.toml" "$clean_home/.pi/agent/settings.json"
printf '%s\n' '[projects."/example"]' 'trust_level = "trusted"' >"$clean_home/.codex/config.toml"
printf '%s\n' '{"theme":"catppuccin-mocha","lastChangelogVersion":"local-state"}' >"$clean_home/.pi/agent/settings.json"
printf '%s\n' 'codex-auth' >"$clean_home/.codex/auth.json"
printf '%s\n' 'pi-auth' >"$clean_home/.pi/agent/auth.json"
cp "$clean_home/.codex/config.toml" "$test_root/codex-original"
cp "$clean_home/.pi/agent/settings.json" "$test_root/pi-original"
run_stow "$clean_home" >"$test_root/owned-output"
run_stow "$clean_home" >/dev/null
[ ! -L "$clean_home/.codex/config.toml" ]
[ ! -L "$clean_home/.pi/agent/settings.json" ]
cmp "$test_root/codex-original" "$clean_home/.codex/config.toml"
cmp "$test_root/pi-original" "$clean_home/.pi/agent/settings.json"
grep -q 'Keeping existing ~/.codex/config.toml' "$test_root/owned-output"
grep -q 'Keeping existing ~/.pi/agent/settings.json' "$test_root/owned-output"
grep -qx 'codex-auth' "$clean_home/.codex/auth.json"
grep -qx 'pi-auth' "$clean_home/.pi/agent/auth.json"
[ ! -e "$clean_home/.pi/agent/themes" ]
[ ! -e "$clean_home/.pi/agent/extensions" ]
assert_no_backups "$clean_home"

# Existing owned settings on the first run are also preserved. Other conflicts
# retain the normal backup-and-stow behavior.
conflict_home="$test_root/conflict"
mkdir -p "$conflict_home/.codex" "$conflict_home/.pi/agent"
cp "$test_root/codex-original" "$conflict_home/.codex/config.toml"
cp "$test_root/pi-original" "$conflict_home/.pi/agent/settings.json"
printf '%s\n' 'original-zshenv' >"$conflict_home/.zshenv"
run_stow "$conflict_home" >/dev/null
run_stow "$conflict_home" >/dev/null
cmp "$test_root/codex-original" "$conflict_home/.codex/config.toml"
cmp "$test_root/pi-original" "$conflict_home/.pi/agent/settings.json"
grep -qx 'original-zshenv' "$conflict_home/.zshenv.backup"
assert_link "$conflict_home/.zshenv" "$REPO_DIR/configs/zsh/.zshenv"
[ "$(find "$conflict_home" -name '*.backup*' | wc -l)" -eq 1 ]

# An external settings link remains active; a blocking parent link must fail
# without moving either the parent or its settings.
linked_home="$test_root/linked"
mkdir -p "$linked_home/.codex" "$test_root/external"
cp "$test_root/codex-original" "$test_root/external/config.toml"
ln -s "$test_root/external/config.toml" "$linked_home/.codex/config.toml"
run_stow "$linked_home" >/dev/null
assert_link "$linked_home/.codex/config.toml" "$test_root/external/config.toml"
rm "$linked_home/.codex/config.toml"
rmdir "$linked_home/.codex"
ln -s "$test_root/external" "$linked_home/.codex"
if run_stow "$linked_home" >"$test_root/parent-output" 2>&1; then
  printf '%s\n' 'Stow unexpectedly replaced a preserved settings parent' >&2
  exit 1
fi
grep -q 'cannot stow through' "$test_root/parent-output"
assert_link "$linked_home/.codex" "$test_root/external"
cmp "$test_root/codex-original" "$test_root/external/config.toml"
assert_no_backups "$linked_home"

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

printf '%s\n' 'Stow deployment, settings preservation, conflict backup, zsh startup, and repeatability passed.'

# ~/.zshenv
# ============================
# XDG Base Directory + ZDOTDIR
# Read by zsh before any other file, even in non-interactive shells.
# ============================

export XDG_CONFIG_HOME="$HOME/.config"
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_CACHE_HOME="$HOME/.cache"
export XDG_STATE_HOME="$HOME/.local/state"
export ZDOTDIR="$XDG_CONFIG_HOME/zsh"

# Java — SDKMAN manages the install; JAVA_HOME exported here for non-interactive shells/hooks
export JAVA_HOME="$HOME/.sdkman/candidates/java/current"
export PATH="$JAVA_HOME/bin:$PATH"

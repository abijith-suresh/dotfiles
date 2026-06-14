# ~/.config/zsh/.zshenv
# Shared zsh environment loaded through ZDOTDIR.

export XDG_CONFIG_HOME="$HOME/.config"
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_CACHE_HOME="$HOME/.cache"
export XDG_STATE_HOME="$HOME/.local/state"
export ZDOTDIR="$XDG_CONFIG_HOME/zsh"

# Keep Go's mutable workspace and caches under XDG directories instead of ~/go.
export GOPATH="${GOPATH:-$XDG_DATA_HOME/go}"
export GOBIN="${GOBIN:-$HOME/.local/bin}"
export GOMODCACHE="${GOMODCACHE:-$XDG_CACHE_HOME/go/pkg/mod}"
export GOCACHE="${GOCACHE:-$XDG_CACHE_HOME/go-build}"

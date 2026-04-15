#!/usr/bin/env bash
# OS / platform detection helpers

is_wsl() {
  grep -qi microsoft /proc/version 2>/dev/null
}

detect_os() {
  if is_wsl; then
    echo "wsl"
    return
  fi

  if [ -f /etc/os-release ]; then
    # shellcheck disable=SC1091
    . /etc/os-release
    case "${ID:-}" in
      ubuntu|debian)
        echo "linux"
        return
        ;;
      fedora)
        echo "fedora"
        return
        ;;
      arch)
        echo "arch"
        return
        ;;
    esac

    case "${ID_LIKE:-}" in
      *debian*) echo "linux"; return ;;
      *fedora*) echo "fedora"; return ;;
      *arch*) echo "arch"; return ;;
    esac
  fi

  if [ "$(uname -s)" = "Darwin" ]; then
    echo "macos"
  else
    echo "unknown"
  fi
}

#!/bin/bash
# install/terminal/select-language.sh
# Interactive language selection — installs via mise

if ! command -v gum &>/dev/null; then
  echo "gum is required. Install it first."
  return 1
fi

if ! command -v mise &>/dev/null; then
  echo "mise is required. Install it first."
  return 1
fi

AVAILABLE_LANGUAGES=("Node.js" "Java" "Python" "Go" "Rust" "Ruby" "PHP" "Elixir")
languages=$(gum choose "${AVAILABLE_LANGUAGES[@]}" --no-limit --height 10 --header "Select programming languages")

if [ -n "$languages" ]; then
  for language in $languages; do
    case $language in
    "Node.js")
      mise use --global node@lts
      echo "  ✓ Node.js LTS"
      ;;
    Java)
      mise use --global java@latest
      echo "  ✓ Java (latest)"
      ;;
    Python)
      mise use --global python@latest
      echo "  ✓ Python (latest)"
      ;;
    Go)
      mise use --global go@latest
      echo "  ✓ Go (latest)"
      ;;
    Rust)
      bash -c "$(curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs)" -- -y
      echo "  ✓ Rust"
      ;;
    Ruby)
      mise use --global ruby@latest
      echo "  ✓ Ruby (latest)"
      ;;
    PHP)
      sudo apt install -y php php-{curl,intl,mbstring,xml,zip} --no-install-recommends
      echo "  ✓ PHP"
      ;;
    Elixir)
      mise use --global erlang@latest
      mise use --global elixir@latest
      echo "  ✓ Elixir + Erlang"
      ;;
    esac
  done
fi

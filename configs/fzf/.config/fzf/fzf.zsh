# ~/.config/fzf/fzf.zsh
# fzf shell integration and configuration

# Enable CTRL-T, CTRL-R, ALT-C keybindings
source <(fzf --zsh)

# Use ripgrep for file finding (respects .gitignore, finds hidden files)
if command -v rg >/dev/null 2>&1; then
  export FZF_DEFAULT_COMMAND='rg --files --hidden --follow --glob "!.git"'
fi

# Official Catppuccin Mocha palette from catppuccin/fzf
if [ -f "${XDG_CONFIG_HOME:-$HOME/.config}/fzf/themes/catppuccin-mocha.sh" ]; then
  source "${XDG_CONFIG_HOME:-$HOME/.config}/fzf/themes/catppuccin-mocha.sh"
fi
export FZF_DEFAULT_OPTS="$FZF_DEFAULT_OPTS --height 40% --layout=reverse --border"

# CTRL-T: file picker with bat preview
if command -v bat >/dev/null 2>&1; then
  export FZF_CTRL_T_OPTS='--preview "bat --color=always --style=numbers {}"'
fi

# ALT-C: directory picker with eza tree preview
if command -v eza >/dev/null 2>&1; then
  export FZF_ALT_C_OPTS='--preview "eza --tree --icons {}"'
fi

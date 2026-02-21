# ~/.config/fzf/fzf.zsh
# fzf shell integration and configuration

# Enable CTRL-T, CTRL-R, ALT-C keybindings
source <(fzf --zsh)

# Use ripgrep for file finding (respects .gitignore, finds hidden files)
export FZF_DEFAULT_COMMAND='rg --files --hidden --follow --glob "!.git"'

# Catppuccin Mocha colour scheme + layout options
export FZF_DEFAULT_OPTS="
  --height 40%
  --layout=reverse
  --border
  --color=bg+:#313244,bg:#1e1e2e,spinner:#f5e0dc,hl:#f38ba8
  --color=fg:#cdd6f4,header:#f38ba8,info:#cba6f7,pointer:#f5e0dc
  --color=marker:#b4befe,fg+:#cdd6f4,prompt:#cba6f7,hl+:#f38ba8
  --color=selected-bg:#45475a
"

# CTRL-T: file picker with bat preview
export FZF_CTRL_T_OPTS='--preview "bat --color=always --style=numbers {}"'

# ALT-C: directory picker with eza tree preview
export FZF_ALT_C_OPTS='--preview "eza --tree --icons {}"'

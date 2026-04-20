# ~/.config/fzf/fzf.zsh
# fzf shell integration and configuration

# Enable CTRL-T, CTRL-R, ALT-C keybindings
source <(fzf --zsh)

# Use ripgrep for file finding (respects .gitignore, finds hidden files)
export FZF_DEFAULT_COMMAND='rg --files --hidden --follow --glob "!.git"'

# Official Catppuccin Mocha palette from catppuccin/fzf
source "${XDG_CONFIG_HOME:-$HOME/.config}/fzf/themes/catppuccin-mocha.sh"
export FZF_DEFAULT_OPTS="$FZF_DEFAULT_OPTS --height 40% --layout=reverse --border"

# CTRL-T: file picker with bat preview
export FZF_CTRL_T_OPTS='--preview "bat --color=always --style=numbers {}"'

# ALT-C: directory picker with eza tree preview
export FZF_ALT_C_OPTS='--preview "eza --tree --icons {}"'

# Create a tmux dev layout with editor, AI, and terminal panes.
# Usage: tdl <command> [args...]

tdl() {
  [[ -z $1 ]] && {
    echo "Usage: tdl <command> [args...]"
    return 1
  }

  [[ -z $TMUX ]] && {
    echo "You must start tmux to use tdl."
    return 1
  }

  local current_dir="$PWD"
  local editor_pane="$TMUX_PANE"
  local ai_cmd="$*"
  local ai_pane

  tmux rename-window -t "$editor_pane" "$(basename "$current_dir")"
  tmux split-window -v -p 15 -t "$editor_pane" -c "$current_dir"
  ai_pane=$(tmux split-window -h -p 30 -t "$editor_pane" -c "$current_dir" -P -F '#{pane_id}')

  tmux send-keys -t "$ai_pane" "$ai_cmd" C-m
  tmux send-keys -t "$editor_pane" "$EDITOR ." C-m
  tmux select-pane -t "$editor_pane"
}

clstart() {
 
 SESSION="MyClaude-$(basename "$PWD")"

 if ! tmux has-session -t "$SESSION" 2>/dev/null; then
  tmux new-session -d -s "$SESSION"
  local claude_pane right_top right_bottom
  claude_pane=$(tmux display-message -t "$SESSION" -p '#{pane_id}')
  right_top=$(tmux split-window -h -p 60 -t "$claude_pane" -P -F '#{pane_id}')
  right_bottom=$(tmux split-window -v -t "$right_top" -P -F '#{pane_id}')

  # il monitor 1984 nella status bar arriva da ~/.tmux.conf: vale per ogni
  # sessione, non serve impostarlo qui.

  tmux select-pane -t "$claude_pane"
  tmux send-keys -t "$claude_pane" "claude" Enter
  sleep 2 && tmux send-keys -t "$claude_pane" Enter &

  tmux send-keys -t "$right_top" "rgr" Enter

  tmux send-keys -t "$right_bottom" "source ./.venv/bin/activate" Enter
 fi

 tmux attach -t "$SESSION"
}

clkill() {
 tmux kill-session -t "MyClaude-$(basename "$PWD")"
}

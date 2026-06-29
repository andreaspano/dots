t4() {
 
 SESSION="T4-$(basename "$PWD")"

 if ! tmux has-session -t "$SESSION" 2>/dev/null; then
  tmux new-session -d -s "$SESSION"
  local first_pane
  first_pane=$(tmux display-message -t "$SESSION" -p '#{pane_id}')
  tmux split-window -h -p 60 -t "$SESSION"
  tmux split-window -v -t "$SESSION"
  tmux select-pane -t "$first_pane"
  tmux send-keys -t "$first_pane" "claude" Enter
  sleep 2 && tmux send-keys -t "$first_pane" Enter &

  tmux send-keys -t "$SESSION.2" "rgr" Enter

  tmux send-keys -t "$SESSION.3" "source ./.venv/bin/activate" Enter
 fi

 tmux attach -t "$SESSION"
}

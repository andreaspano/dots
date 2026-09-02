c1() {

 SESSION="MyClaude-$(basename "$PWD")"

 if ! tmux has-session -t "$SESSION" 2>/dev/null; then
  tmux new-session -d -s "$SESSION" -x 220 -y 50
  local claude_pane right_top right_bottom
  claude_pane=$(tmux display-message -t "$SESSION" -p '#{pane_id}')
  right_top=$(tmux split-window -h -l 132 -t "$claude_pane" -P -F '#{pane_id}')
  right_bottom=$(tmux split-window -v -t "$right_top" -P -F '#{pane_id}')

  # il monitor 1984 nella status bar arriva da ~/.tmux.conf: vale per ogni
  # sessione, non serve impostarlo qui.

  tmux select-pane -t "$claude_pane"
  tmux send-keys -t "$claude_pane" "claude" Enter
  sleep 2 && tmux send-keys -t "$claude_pane" Enter &

  # lets vim (opened from ranger in right_top) find the console pane to send
  # visual selections to via q, see vimrc
  tmux send-keys -t "$right_top" "export MYCLAUDE_CONSOLE_PANE=$right_bottom" Enter
  tmux send-keys -t "$right_top" "rgr" Enter

  # bracketed paste lets IPython take a tmux paste-buffer (from the vimrc `q`
  # mapping) as one atomic block, instead of autoindenting it line-by-line
  # and needing a manual ';' to force execution of a hung continuation block
  tmux send-keys -t "$right_bottom" "alias ipython='ipython --TerminalInteractiveShell.enable_bracketed_paste=True'" Enter
  tmux send-keys -t "$right_bottom" "source ./.venv/bin/activate" Enter
 fi

 tmux attach -t "$SESSION"
}

c0() {
 tmux kill-session -t "MyClaude-$(basename "$PWD")"
}

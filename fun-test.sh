c1() {

 SESSION="MyClaude-$(basename "$PWD")"

 if ! tmux has-session -t "$SESSION" 2>/dev/null; then
  tmux new-session -d -s "$SESSION" -x 220 -y 50
  local bash_pane left_top left_bottom claude_pane
  left_top=$(tmux display-message -t "$SESSION" -p '#{pane_id}')
  claude_pane=$(tmux split-window -h -l 87 -t "$left_top" -P -F '#{pane_id}')
  bash_pane=$(tmux split-window -h -b -l 40 -t "$left_top" -P -F '#{pane_id}')
  left_bottom=$(tmux split-window -v -t "$left_top" -P -F '#{pane_id}')

  # il monitor 1984 nella status bar arriva da ~/.tmux.conf: vale per ogni
  # sessione, non serve impostarlo qui.

  tmux select-pane -t "$claude_pane"
  tmux send-keys -t "$claude_pane" "claude" Enter
  sleep 2 && tmux send-keys -t "$claude_pane" Enter &

  # lets vim (sent here from ranger's rifle.conf via MYCLAUDE_EDITOR_PANE)
  # find the console pane to send visual selections to via q, see vimrc
  tmux send-keys -t "$left_top" "export MYCLAUDE_CONSOLE_PANE=$left_bottom" Enter

  # start vim here and keep it running: rifle.conf's MYCLAUDE_EDITOR_PANE rule
  # sends selected files to it via `:tab drop`, so it needs to already be
  # running (not a plain shell) for that to land as a vim command
  tmux send-keys -t "$left_top" "vim" Enter

  # ranger runs in bash_pane; MYCLAUDE_EDITOR_PANE tells its rifle.conf rule
  # to open selected files in left_top's vim instead of in-place
  tmux send-keys -t "$bash_pane" "export MYCLAUDE_EDITOR_PANE=$left_top" Enter
  tmux send-keys -t "$bash_pane" "rgr" Enter

  # bracketed paste lets IPython take a tmux paste-buffer (from the vimrc `q`
  # mapping) as one atomic block, instead of autoindenting it line-by-line
  # and needing a manual ';' to force execution of a hung continuation block
  tmux send-keys -t "$left_bottom" "alias ipython='ipython --TerminalInteractiveShell.enable_bracketed_paste=True'" Enter
  tmux send-keys -t "$left_bottom" "source ./.venv/bin/activate" Enter
  tmux send-keys -t "$left_bottom" "ipython" Enter
 fi

 tmux attach -t "$SESSION"
}

c0() {
 tmux kill-session -t "MyClaude-$(basename "$PWD")"
}

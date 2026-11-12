clstart() {
 
 SESSION="MyClaude-$(basename "$PWD")"

 # tmux legge ~/.tmux.conf solo all'avvio del server: se un server è già in
 # piedi (anche per un'altra sessione) lo ricarichiamo, così le modifiche a
 # tmux.conf arrivano senza doverlo riavviare. Senza server il comando
 # fallisce in silenzio e la new-session qui sotto parte già aggiornata.
 tmux source-file ~/.tmux.conf 2>/dev/null

 if ! tmux has-session -t "$SESSION" 2>/dev/null; then
  tmux new-session -d -s "$SESSION" -x 220 -y 50
  local claude_pane right_top right_bottom
  claude_pane=$(tmux display-message -t "$SESSION" -p '#{pane_id}')
  right_top=$(tmux split-window -h -l 132 -t "$claude_pane" -P -F '#{pane_id}')
  right_bottom=$(tmux split-window -v -t "$right_top" -P -F '#{pane_id}')

  # il monitor 1984 nella status bar arriva da ~/.tmux.conf: vale per ogni
  # sessione, non serve impostarlo qui.

  # Su mutolo tmux dipinge i pannelli Solarized Light (vedi tmux.conf): il
  # tema di Claude Code deve essere chiaro, e "light-ansi" usa la palette del
  # profilo terminale, cioè proprio i colori Solarized. Il tema vive in
  # ~/.claude.json (per macchina), quindi lo fissiamo lì prima di lanciare.
  if [ "$(hostname -s)" = "mutolo" ]; then
   python3 - <<'EOF'
import json, os
p = os.path.expanduser("~/.claude.json")
try:
    cfg = json.load(open(p))
except FileNotFoundError:
    cfg = {}
except ValueError:
    cfg = None  # file illeggibile: non toccarlo
if cfg is not None and cfg.get("theme") != "light-ansi":
    cfg["theme"] = "light-ansi"
    tmp = p + ".tmp"
    json.dump(cfg, open(tmp, "w"), indent=2)
    os.replace(tmp, p)
EOF
  fi

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

z() {
  command -v fzf >/dev/null 2>&1 || { echo "fzf non installato"; return 1; }

  local cmd
  cmd="$(history \
    | fzf --tac --reverse --prompt="⌛ Seleziona un comando: " \
    | sed 's/^[ ]*[0-9]\+[ ]*//')"

  if [[ -n "$cmd" ]]; then
    printf '\n  Eseguo: \033[1m%s\033[0m\n' "$cmd"
    eval "$cmd"
  fi
}

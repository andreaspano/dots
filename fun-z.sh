z() {
  command -v fzf >/dev/null 2>&1 || { echo "fzf non installato"; return 1; }

  local cmd
  # HISTTIMEFORMAT='' -> history stampa solo "  N  comando" (senza data/ora)
  cmd="$(HISTTIMEFORMAT='' history \
    | sed -E 's/^[[:space:]]*[0-9]+[[:space:]]+//' \
    | grep -vE '^z([[:space:]]|$)' \
    | tac \
    | awk '!seen[$0]++' \
    | fzf --no-sort --reverse --query="$*" \
          --prompt="⌛ Seleziona un comando: ")"

  [[ -n "$cmd" ]] || return 0

  # Registra comunque il comando in history: così è raggiungibile con ↑
  # anche se il terminale non risponde alla query DSR qui sotto.
  # (HISTCONTROL=ignoredups evita il doppione quando poi premi Invio.)
  history -s "$cmd"

  # Mette il comando sulla riga di prompt: si può modificare e si esegue
  # solo premendo Invio. Il terminale risponde a \e[5n con \e[0n, che
  # readline traduce nella macro appena definita.
  local esc=${cmd//\\/\\\\}
  esc=${esc//\"/\\\"}
  if [[ $- == *i* ]] && bind "\"\e[0n\": \"$esc\"" 2>/dev/null; then
    printf '\e[5n'
  else
    printf '%s\n' "$cmd"
  fi
}

a() {
  if [[ ! -f "$PWD/.venv/bin/activate" ]]; then
    echo "Creo il venv in $PWD/.venv"
    python3 -m venv "$PWD/.venv" || { echo "creazione venv fallita"; return 1; }
  fi
  source "$PWD/.venv/bin/activate"
}


rgr() {
  local start_dir
  start_dir="$(realpath "${1:-$PWD}")" || return 1

  if [ ! -d "$start_dir" ]; then
    echo "rgr: not a directory: $start_dir" >&2
    return 1
  fi

  local plugin_link="$HOME/.config/ranger/plugins/jail.py"
  mkdir -p "$(dirname "$plugin_link")"

  # jail.py lives in ~/dev/dots/jail.py; only restricts navigation when
  # RANGER_JAIL_ROOT is set, so plain `ranger` invocations are unaffected.
  if [ ! -e "$plugin_link" ]; then
    ln -s "$HOME/dev/dots/jail.py" "$plugin_link"
  fi

  RANGER_JAIL_ROOT="$start_dir" ranger "$start_dir"
}

# Project

prj() {
  local name="$1"
  if [[ -z "$name" ]]; then
    echo "usage: prj <name>"
    return 1
  fi
  uv init --package "$name"
  cd "$name" || return 1
  uv venv
  source .venv/bin/activate
  echo -e "\nHappy journey\n"
}

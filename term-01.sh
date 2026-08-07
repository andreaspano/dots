#!/usr/bin/env bash
# term-01.sh — GNOME Terminal profiles as version-controlled text.
#
# The profiles themselves live in dconf, a binary database at
# ~/.config/dconf/user that holds every GNOME setting on the machine. There is
# no per-profile file to commit, so this script is the file: the DATA section
# below is the authoritative copy, and git tracks it like any other dotfile.
#
#   bash term-01.sh          apply the profiles below to dconf (default)
#   bash term-01.sh load     same thing, spelled out
#   bash term-01.sh save     the reverse — rewrite this script's DATA section
#                            from whatever is currently in dconf, so tweaks
#                            made in Preferences become committable
#   bash term-01.sh diff     show how dconf differs from this file
#
# Colors apply to open windows immediately; font and cell scaling need a new
# window.

set -euo pipefail

SELF="$(readlink -f "${BASH_SOURCE[0]}")"
ROOT=/org/gnome/terminal/legacy/profiles:

# UUIDs are stable per profile and are what dconf keys are named after.
# Order here is the order they appear in Preferences.
PROFILES=(
  "b1dcc9dd-5262-4d8d-a863-c897e6d979b9:soldark"
  "d1dfd885-e9d5-4e38-bb69-72bb8deff888:matrix"
  "f2f518fe-6516-4eb4-a503-246552bf300d:andrea"
)
DEFAULT_PROFILE=f2f518fe-6516-4eb4-a503-246552bf300d

command -v dconf >/dev/null || { echo "term-01: dconf not found" >&2; exit 1; }

# ---------------------------------------------------------------- load -------
do_load() {
  local uuid name
  for entry in "${PROFILES[@]}"; do
    uuid="${entry%%:*}"; name="${entry#*:}"
    # sed pulls one profile's block out of the DATA section at the bottom.
    sed -n "/^### BEGIN ${uuid}\$/,/^### END ${uuid}\$/p" "$SELF" \
      | sed '1d;$d' \
      | dconf load "${ROOT}/:${uuid}/"
    echo "  loaded ${name}"
  done

  # Registering the list matters on a fresh machine, where these profiles do
  # not exist yet and would otherwise never show up in Preferences.
  local list=""
  for entry in "${PROFILES[@]}"; do list+="'${entry%%:*}', "; done
  dconf write "${ROOT}/list" "[${list%, }]"
  dconf write "${ROOT}/default" "'${DEFAULT_PROFILE}'"
  echo "  registered profile list, default = ${DEFAULT_PROFILE}"
}

# ---------------------------------------------------------------- save -------
# Rewrites this file: everything above the DATA marker is kept verbatim, then
# fresh dconf dumps are appended. Written to a temp file and syntax-checked
# before replacing the original, so a failure here cannot destroy the script.
do_save() {
  local tmp; tmp="$(mktemp)"
  sed -n '1,/^### DATA$/p' "$SELF" > "$tmp"
  local uuid name
  for entry in "${PROFILES[@]}"; do
    uuid="${entry%%:*}"; name="${entry#*:}"
    { echo; echo "### BEGIN ${uuid}"; dconf dump "${ROOT}/:${uuid}/"; echo "### END ${uuid}"; } >> "$tmp"
    echo "  saved ${name}"
  done
  bash -n "$tmp" || { echo "term-01: refusing to write, generated file is broken" >&2; rm -f "$tmp"; exit 1; }
  chmod --reference="$SELF" "$tmp"
  mv "$tmp" "$SELF"
  echo "  wrote ${SELF}"
}

# ---------------------------------------------------------------- diff -------
do_diff() {
  local uuid name rc=0
  for entry in "${PROFILES[@]}"; do
    uuid="${entry%%:*}"; name="${entry#*:}"
    if ! diff -u \
        <(sed -n "/^### BEGIN ${uuid}\$/,/^### END ${uuid}\$/p" "$SELF" | sed '1d;$d') \
        <(dconf dump "${ROOT}/:${uuid}/") \
        --label "term-01.sh (${name})" --label "dconf (${name})"; then
      rc=1
    fi
  done
  (( rc == 0 )) && echo "  in sync"
  return 0
}

case "${1:-load}" in
  load|"") do_load ;;
  save)    do_save ;;
  diff)    do_diff ;;
  *) echo "usage: term-01.sh [load|save|diff]" >&2; exit 2 ;;
esac

exit 0

### DATA

### BEGIN b1dcc9dd-5262-4d8d-a863-c897e6d979b9
[/]
background-color='rgb(0,43,54)'
font='Noto Mono 12'
foreground-color='rgb(131,148,150)'
use-system-font=false
use-theme-colors=false
visible-name='soldark'
### END b1dcc9dd-5262-4d8d-a863-c897e6d979b9

### BEGIN d1dfd885-e9d5-4e38-bb69-72bb8deff888
[/]
audible-bell=false
background-color='#050A05'
bold-color='#A6FFBF'
bold-color-same-as-fg=false
cell-height-scale=1.1000000000000001
cell-width-scale=1.0
cursor-background-color='#00FF41'
cursor-blink-mode='on'
cursor-colors-set=true
cursor-foreground-color='#050A05'
cursor-shape='block'
font='JetBrainsMonoNL Nerd Font 12'
foreground-color='#4DE87A'
highlight-background-color='#00FF41'
highlight-colors-set=true
highlight-foreground-color='#050A05'
palette=['#050A05', '#D45A5A', '#2FB84C', '#7FCF4A', '#2FA97A', '#4FCF8F', '#35C79A', '#9BE8AE', '#3E7A4E', '#FF6B6B', '#4DFF7A', '#A6F55C', '#52D9A8', '#7BEFB8', '#5CF0C4', '#D6FFE0']
scrollback-unlimited=true
use-system-font=false
use-theme-colors=false
visible-name='matrix'
### END d1dfd885-e9d5-4e38-bb69-72bb8deff888

### BEGIN f2f518fe-6516-4eb4-a503-246552bf300d
[/]
audible-bell=false
background-color='#1B1E20'
bold-color='#F2EDE3'
bold-color-same-as-fg=false
cell-height-scale=1.1000000000000001
cell-width-scale=1.0
cursor-background-color='#F3A90A'
cursor-blink-mode='off'
cursor-colors-set=true
cursor-foreground-color='#1B1E20'
cursor-shape='block'
font='JetBrainsMonoNL Nerd Font 12'
foreground-color='#D8D2C6'
highlight-background-color='#F3A90A'
highlight-colors-set=true
highlight-foreground-color='#1B1E20'
palette=['#1B1E20', '#E05A5A', '#7FB971', '#E0A33A', '#6C9BD6', '#B58BC4', '#58B8B8', '#D8D2C6', '#5A6063', '#FF7B72', '#A8E28D', '#F3A90A', '#8FBCEB', '#D9AEE8', '#7FE0E0', '#F2EDE3']
scrollback-unlimited=true
use-system-font=false
use-theme-colors=false
visible-name='andrea'
### END f2f518fe-6516-4eb4-a503-246552bf300d

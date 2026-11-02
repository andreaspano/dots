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
  "6443a06c-9cf2-44bf-8c5d-baf9047618a9:ernesto"
  "8a419f07-1000-43e7-a6f1-fa6c24fd57ed:mutolo"
)
DEFAULT_PROFILE=6443a06c-9cf2-44bf-8c5d-baf9047618a9

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

### BEGIN 6443a06c-9cf2-44bf-8c5d-baf9047618a9
[/]
audible-bell=false
background-color='#192330'
bold-color='#e4e4e5'
bold-color-same-as-fg=false
cell-height-scale=1.1000000000000001
cell-width-scale=1.0
cursor-background-color='#cdcecf'
cursor-blink-mode='on'
cursor-colors-set=true
cursor-foreground-color='#192330'
cursor-shape='block'
font='JetBrainsMonoNL Nerd Font 12'
foreground-color='#cdcecf'
highlight-background-color='#2b3b51'
highlight-colors-set=true
highlight-foreground-color='#cdcecf'
palette=['#393b44', '#c94f6d', '#81b29a', '#dbc074', '#719cd6', '#9d79d6', '#63cdcf', '#dfdfe0', '#575860', '#d16983', '#8ebaa4', '#e0c989', '#86abdc', '#baa1e2', '#7ad5d6', '#e4e4e5']
scrollback-unlimited=true
use-system-font=false
use-theme-colors=false
visible-name='ernesto'
### END 6443a06c-9cf2-44bf-8c5d-baf9047618a9

### BEGIN 8a419f07-1000-43e7-a6f1-fa6c24fd57ed
[/]
audible-bell=false
background-color='#fdf6e3'
bold-color='#073642'
bold-color-same-as-fg=false
cell-height-scale=1.1000000000000001
cell-width-scale=1.0
cursor-background-color='#586e75'
cursor-blink-mode='off'
cursor-colors-set=true
cursor-foreground-color='#fdf6e3'
cursor-shape='block'
font='JetBrainsMonoNL Nerd Font 12'
foreground-color='#657b83'
highlight-background-color='#eee8d5'
highlight-colors-set=true
highlight-foreground-color='#586e75'
palette=['#073642', '#dc322f', '#859900', '#b58900', '#268bd2', '#d33682', '#2aa198', '#586e75', '#93a1a1', '#cb4b16', '#859900', '#b58900', '#268bd2', '#6c71c4', '#2aa198', '#002b36']
scrollback-unlimited=true
use-system-font=false
use-theme-colors=false
visible-name='mutolo'
### END 8a419f07-1000-43e7-a6f1-fa6c24fd57ed

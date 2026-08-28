# switch <profile-name> — repaint the current terminal tab with the colors
# of a GNOME Terminal profile (as managed by term-01.sh), by visible-name.
#
# GNOME Terminal has no way to reassign an already-open tab to a different
# profile object, so this reads the target profile's colors straight out of
# dconf and pushes them into the running terminal via OSC escape sequences
# (the same mechanism tools like base16-shell use). Font and cell scaling
# are profile-creation-time settings and can't be changed this way.

_switch_to_hex() {
  local raw="${1//\'/}"
  if [[ "$raw" =~ ^rgb\(([0-9]+),[[:space:]]*([0-9]+),[[:space:]]*([0-9]+)\)$ ]]; then
    printf '#%02x%02x%02x' "${BASH_REMATCH[1]}" "${BASH_REMATCH[2]}" "${BASH_REMATCH[3]}"
  else
    printf '%s' "$raw"
  fi
}

switch() {
  command -v dconf >/dev/null || { echo "switch: dconf not found" >&2; return 1; }
  local name="$1"
  [[ -n "$name" ]] || { echo "usage: switch <profile-name>" >&2; return 1; }

  local root=/org/gnome/terminal/legacy/profiles: uuid vname found=""
  local d
  for d in $(dconf list "${root}/"); do
    [[ "$d" == :*/ ]] || continue
    uuid="${d#:}"; uuid="${uuid%/}"
    vname="$(dconf read "${root}/:${uuid}/visible-name")"
    vname="${vname//\'/}"
    if [[ "${vname,,}" == "${name,,}" ]]; then
      found="$uuid"
      break
    fi
  done
  [[ -n "$found" ]] || { echo "switch: no profile named '$name'" >&2; return 1; }

  local base="${root}/:${found}/"
  local bg fg cbg hbg hfg
  bg="$(_switch_to_hex "$(dconf read "${base}background-color")")"
  fg="$(_switch_to_hex "$(dconf read "${base}foreground-color")")"
  cbg="$(_switch_to_hex "$(dconf read "${base}cursor-background-color")")"
  hbg="$(_switch_to_hex "$(dconf read "${base}highlight-background-color")")"
  hfg="$(_switch_to_hex "$(dconf read "${base}highlight-foreground-color")")"

  [[ -n "$bg" ]]  && printf '\e]11;%s\a' "$bg"
  [[ -n "$fg" ]]  && printf '\e]10;%s\a' "$fg"
  [[ -n "$cbg" ]] && printf '\e]12;%s\a' "$cbg"
  [[ -n "$hbg" ]] && printf '\e]17;%s\a' "$hbg"
  [[ -n "$hfg" ]] && printf '\e]19;%s\a' "$hfg"

  local palette i=0 c
  palette="$(dconf read "${base}palette")"
  if [[ -n "$palette" ]]; then
    palette="${palette#\[}"; palette="${palette%\]}"
    IFS=',' read -ra colors <<< "$palette"
    for c in "${colors[@]}"; do
      c="$(_switch_to_hex "${c// /}")"
      printf '\e]4;%d;%s\a' "$i" "$c"
      ((i++))
    done
  fi

  echo "switch: applied '$name'"
}

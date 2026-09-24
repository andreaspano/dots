#!/bin/bash
# SDG Calendar in surf: focus the window if it's already open, otherwise open it.
TITLE="SDG Group - Calendar"
URL="https://calendar.google.com/calendar/r?authuser=andrea.spano@sdggroup.com"
COOKIES="$HOME/.surf/sdg-cookies.txt"   # same SDG-only surf session as gmail.sh

# focus an existing window (needs wmctrl: sudo apt install wmctrl)
if command -v wmctrl >/dev/null && wmctrl -l | grep -qi "$TITLE"; then
    wmctrl -a "$TITLE"
    exit 0
fi

# exec -a names the window (WM_CLASS) so the panel groups it under sdg-calendar.desktop
(exec -a sdg-calendar surf -c "$COOKIES" "$URL" >/dev/null 2>&1) &
# old: google-chrome --app=https://calendar.google.com --profile-directory=Default

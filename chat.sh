#!/bin/bash
# SDG Google Chat in surf: focus the window if it's already open, otherwise open it.
CLASS="sdg-chat"   # window class set via exec -a below; matches StartupWMClass in sdg-chat.desktop
URL="https://chat.google.com/"   # the SDG cookie file only holds the SDG account, so no authuser needed
COOKIES="$HOME/.surf/sdg-cookies.txt"   # same SDG-only surf session as gmail.sh / calendar.sh / sdrive.sh

# focus an existing window by class, so a spano.it Chat window is never picked (needs wmctrl)
if command -v wmctrl >/dev/null && wmctrl -lx | grep -q "$CLASS\.Surf"; then
    wmctrl -x -a "$CLASS.Surf"
    exit 0
fi

(exec -a "$CLASS" surf -c "$COOKIES" "$URL" >/dev/null 2>&1) &
# old: google-chrome --app=https://chat.google.com --profile-directory=Default

#!/bin/bash
# SDG Google Drive in surf: focus the window if it's already open, otherwise open it.
CLASS="sdg-sdrive"   # window class set via exec -a below; matches StartupWMClass in sdg-sdrive.desktop
URL="https://drive.google.com/drive/my-drive?authuser=andrea.spano@sdggroup.com"
COOKIES="$HOME/.surf/sdg-cookies.txt"   # same SDG-only surf session as gmail.sh / calendar.sh

# focus an existing window by class, so a spano.it Drive window is never picked (needs wmctrl)
if command -v wmctrl >/dev/null && wmctrl -lx | grep -q "$CLASS\.Surf"; then
    wmctrl -x -a "$CLASS.Surf"
    exit 0
fi

(exec -a "$CLASS" surf -c "$COOKIES" "$URL" >/dev/null 2>&1) &
# old: google-chrome --app=https://drive.google.com/drive/my-drive --profile-directory=Default

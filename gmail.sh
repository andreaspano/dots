#!/bin/bash
# SDG Gmail in surf: focus the window if it's already open, otherwise open it.
TITLE="SDG Group Mail"
URL="https://mail.google.com/mail/u/?authuser=andrea.spano@sdggroup.com"
COOKIES="$HOME/.surf/sdg-cookies.txt"   # SDG-only surf session, kept apart from spano.it (~/.surf/cookies.txt)

# focus an existing window (needs wmctrl: sudo apt install wmctrl)
if command -v wmctrl >/dev/null && wmctrl -l | grep -qi "$TITLE"; then
    wmctrl -a "$TITLE"
    exit 0
fi

# exec -a names the window (WM_CLASS) so the panel groups it under sdg-gmail.desktop
(exec -a sdg-gmail surf -c "$COOKIES" "$URL" >/dev/null 2>&1) &
# old: google-chrome --app=https://mail.google.com --profile-directory=Default

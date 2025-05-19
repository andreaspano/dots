#!/bin/bash
var="SDG Group Mail"
if wmctrl -l | grep -i "SDG Group Mail"; then
    wmctrl -a "SDG Group Mail"
else
    #google-chrome --new-window https://mail.google.com
    google-chrome -app=https://mail.google.com  --profile-directory=Default
fi


#!/bin/bash
var="- Chat"
if wmctrl -l | grep -i i $var; then
    wmctrl -a $var
else
    #google-chrome --new-window https://mail.google.com
    google-chrome -app=https://chat.google.com  --profile-directory=Default
fi


#!/bin/bash
if wmctrl -l | grep -i "SDG Group - Calendar"; then
    wmctrl -a "SDG Group - Calendar"
else
    google-chrome -app=https://calendar.google.com  --profile-directory=Default
fi


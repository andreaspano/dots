#!/bin/bash
var="Google Drive"
if wmctrl -l | grep -i "Google Drive"; then
    wmctrl -a "Google Drive"
else
    #google-chrome --new-window https://mail.google.com
    google-chrome -app=https://drive.google.com/drive/my-drive  --profile-directory=Default
fi


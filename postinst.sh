#!/bin/bash

## Setting proper permissions to avois launchd errors.
chown root /Library/LaunchDaemons/am.theiostre.folderalbums.daemon.plist
chmod 644 /Library/LaunchDaemons/am.theiostre.folderalbums.daemon.plist

## Restarting foldalbumd
launchctl unload /Library/LaunchDaemons/am.theiostre.folderalbums.daemon.plist
launchctl load /Library/LaunchDaemons/am.theiostre.folderalbums.daemon.plist
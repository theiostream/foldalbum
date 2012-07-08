#!/bin/bash

## Setting proper permissions to avois launchd errors.
chown root /System/Library/LaunchDaemons/am.theiostre.folderalbums.daemon.plist
chmod 644 /System/Library/LaunchDaemons/am.theiostre.folderalbums.daemon.plist

## Restarting foldalbumd
launchctl unload /System/Library/LaunchDaemons/am.theiostre.folderalbums.daemon.plist
launchctl load /System/Library/LaunchDaemons/am.theiostre.folderalbums.daemon.plist
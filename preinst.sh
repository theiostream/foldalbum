#!/bin/bash

## Remove old plist to avoid the damn issues.

## NOTE THAT THIS WAS WHAT I WANTED TO AVOID.
## BUT APPARENTLY THERE WAS A BUG WITH CONVERSION
## FROM v1.0 PLISTS TO v1.1 PLISTS AND TO AVOID
## EVEN MORE PEOPLE COMPLAINING I JUST DID THIS.
##
## REALLY SORRY FOR THE INCONVENIENCE.
## AND IF I SEEM TO BE SHOUTING AT YOU TOO.

if [ -e /var/mobile/Library/Preferences/am.theiostre.foldalbum.plist ]; then
	if [ ! -e /Library/Application\ Support/FoldAlbum/_patched_plist ]; then
		echo "To be *sure* to avoid issues with v1.0 users, the file which stores your music folders /might/ be deleted. Please re-add your folders as you did in previous versions."
		
		# Let's keep it just in case.
		mv -f /var/mobile/Library/Preferences/am.theiostre.foldalbum.plist /Library/Application\ Support/FoldAlbum/_oldplist.plist
		touch /Library/Application\ Support/FoldAlbum/_patched_plist
	fi
fi
#!/bin/bash

##########
##  preinst.sh
##	
##	FoldMusic
## 	version 1.2.0, July 15th, 2012
##
##  Copyright (C) 2012 theiostream
##
##  This software is provided 'as-is', without any express or implied
##  warranty.  In no event will the authors be held liable for any damages
##  arising from the use of this software.
##
##  Permission is granted to anyone to use this software for any purpose,
##  including commercial applications, and to alter it and redistribute it
##  freely, subject to the following restrictions:
##
##  1. The origin of this software must not be misrepresented; you must not
##     claim that you wrote the original software. If you use this software
##     in a product, an acknowledgment in the product documentation would be
##     appreciated but is not required.
##  2. Altered source versions must be plainly marked as such, and must not be
##     misrepresented as being the original software.
##  3. This notice may not be removed or altered from any source distribution.
##
##  theiostream
##  matoe@matoe.co.cc
##########

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

else
	touch /Library/Application\ Support/FoldAlbum/_patched_plist

fi
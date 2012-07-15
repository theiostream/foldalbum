##########
##  fapreferences/Makefile
##  (uses theos by Dustin Howett)
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

include theos/makefiles/common.mk

BUNDLE_NAME = FAPreferences
FAPreferences_FILES = FAPreferences.mm FAMediaPickerController.m MPMediaItemCollection+Playable.m
FAPreferences_INSTALL_PATH = /Library/PreferenceBundles
FAPreferences_FRAMEWORKS = UIKit MediaPlayer
FAPreferences_PRIVATE_FRAMEWORKS = Preferences AppSupport

include $(THEOS_MAKE_PATH)/bundle.mk

internal-stage::
	# Send PreferenceLoader plist to its place
	$(ECHO_NOTHING)mkdir -p $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences$(ECHO_END)
	$(ECHO_NOTHING)cp entry.plist $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences/FAPreferences.plist$(ECHO_END)
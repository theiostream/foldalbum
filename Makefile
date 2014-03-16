##########
##  Makefile
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

TARGET = ::4.3
ARCHS = armv7 arm64

include theos/makefiles/common.mk

# Yup. No longer foldalbumd.
SUBPROJECTS = FAPreferences

TWEAK_NAME = FolderAlbums
FolderAlbums_FILES = Tweak.xm FAPreferencesHandler.m FANotificationHandler.mm FAFolderCell.m FACalloutView.m
FolderAlbums_FRAMEWORKS = MediaPlayer UIKit CoreGraphics QuartzCore
FolderAlbums_PRIVATE_FRAMEWORKS = AppSupport

include $(THEOS_MAKE_PATH)/tweak.mk
include $(THEOS_MAKE_PATH)/aggregate.mk

internal-stage::
	$(ECHO_NOTHING)mkdir -p $(THEOS_STAGING_DIR)/DEBIAN$(ECHO_END)
	$(ECHO_NOTHING)cp prerm2.sh $(THEOS_STAGING_DIR)/DEBIAN/prerm$(ECHO_END)
	
	$(ECHO_NOTHING)mkdir -p $(THEOS_STAGING_DIR)/Library/Application\ Support/$(ECHO_END)
	$(ECHO_NOTHING)cp -r Resources/ $(THEOS_STAGING_DIR)/Library/Application\ Support/FoldAlbum$(ECHO_END)

after-install::
	install.exec "killall -9 backboardd"

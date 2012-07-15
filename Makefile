include theos/makefiles/common.mk

SUBPROJECTS = FAPreferences foldalbumd

TWEAK_NAME = FolderAlbums
FolderAlbums_FILES  = Tweak.xm FAPreferencesHandler.m FANotificationHandler.mm FAFolderCell.m FACalloutView.m
FolderAlbums_FILES += UIImage+Alpha.m UIImage+RoundedCorner.m UIImage+Resize.m UIImage+ProportionalFill.m
FolderAlbums_FRAMEWORKS = MediaPlayer UIKit CoreGraphics QuartzCore
FolderAlbums_PRIVATE_FRAMEWORKS = AppSupport MobileIcons

include $(THEOS_MAKE_PATH)/tweak.mk
include $(THEOS_MAKE_PATH)/aggregate.mk

internal-stage::
	$(ECHO_NOTHING)mkdir -p $(THEOS_STAGING_DIR)/DEBIAN$(ECHO_END)
	$(ECHO_NOTHING)cp preinst.sh $(THEOS_STAGING_DIR)/DEBIAN/preinst$(ECHO_END)
	$(ECHO_NOTHING)cp postinst.sh $(THEOS_STAGING_DIR)/DEBIAN/postinst$(ECHO_END)
	$(ECHO_NOTHING)cp prerm.sh $(THEOS_STAGING_DIR)/DEBIAN/prerm$(ECHO_END)
	
	$(ECHO_NOTHING)mkdir -p $(THEOS_STAGING_DIR)/Library/Application\ Support/$(ECHO_END)
	$(ECHO_NOTHING)cp -r Resources/ $(THEOS_STAGING_DIR)/Library/Application\ Support/FoldAlbum$(ECHO_END)
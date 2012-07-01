include theos/makefiles/common.mk

SUBPROJECTS = FAPreferences foldalbumd

TWEAK_NAME = FolderAlbums
FolderAlbums_FILES  = Tweak.xm FAPreferencesHandler.m FANotificationHandler.mm FAFolderCell.m FACalloutView.m
FolderAlbums_FILES += UIImage+Alpha.m UIImage+RoundedCorner.m UIImage+Resize.m
FolderAlbums_FRAMEWORKS = MediaPlayer UIKit CoreGraphics QuartzCore
FolderAlbums_PRIVATE_FRAMEWORKS = AppSupport

include $(THEOS_MAKE_PATH)/tweak.mk
include $(THEOS_MAKE_PATH)/aggregate.mk
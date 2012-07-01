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
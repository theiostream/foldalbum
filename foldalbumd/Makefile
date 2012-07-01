include theos/makefiles/common.mk

TOOL_NAME = foldalbumd
foldalbumd_FILES = main.mm
foldalbumd_FRAMEWORKS = MediaPlayer
foldalbumd_PRIVATE_FRAMEWORKS = AppSupport

include $(THEOS_MAKE_PATH)/tool.mk

internal-stage::
	$(ECHO_NOTHING)mkdir -p $(THEOS_STAGING_DIR)/System/Library/LaunchDaemons$(ECHO_END)
	$(ECHO_NOTHING)cp am.theiostre.folderalbums.daemon.plist $(THEOS_STAGING_DIR)/System/Library/LaunchDaemons/$(ECHO_END)
	
	#$(ECHO_NOTHING)mkdir -p $(THEOS_STAGING_DIR)/DEBIAN$(ECHO_END)
	#$(ECHO_NOTHING)cp postinst $(THEOS_STAGING_DIR)/DEBIAN/$(ECHO_END)
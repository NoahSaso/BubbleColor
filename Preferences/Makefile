ARCHS = arm64 armv7

include theos/makefiles/common.mk

BUNDLE_NAME = BubbleColor
BubbleColor_FILES = BubbleColor.mm HeaderCell.mm CustomColorListController.mm
BubbleColor_INSTALL_PATH = /Library/PreferenceBundles
BubbleColor_FRAMEWORKS = UIKit CoreGraphics QuartzCore
BubbleColor_PRIVATE_FRAMEWORKS = Preferences
ADDITIONAL_CFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/bundle.mk

internal-stage::
	$(ECHO_NOTHING)mkdir -p $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences$(ECHO_END)
	$(ECHO_NOTHING)cp entry.plist $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences/BubbleColor.plist$(ECHO_END)

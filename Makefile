ARCHS = armv7 arm64

include theos/makefiles/common.mk

TWEAK_NAME = BubbleColor
BubbleColor_FILES = Tweak.xm
BubbleColor_FRAMEWORKS = UIKit

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 MobileSMS; killall -9 Preferences"
SUBPROJECTS += Preferences
include $(THEOS_MAKE_PATH)/aggregate.mk

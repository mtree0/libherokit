include theos/makefiles/common.mk

TWEAK_NAME = HeroKitExample
HeroKitExample_FILES = Tweak.xm
HeroKitExample_FRAMEWORKS = Foundation UIKit
HeroKitExample_LDFLAGS = -lherokit

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 SpringBoard"

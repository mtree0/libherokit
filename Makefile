GO_EASY_ON_ME = 1
TARGET = iphone:6.0:5.0
THEOS_DEVICE_IP = 127.0.0.1 -p 2323

include theos/makefiles/common.mk

TWEAK_NAME = libherokit
libherokit_FILES = Tweak.xm
libherokit_FRAMEWORKS = Foundation UIKit AVFoundation AudioToolbox
libherokit_PRIVATE_FRAMEWORKS = BackBoardServices

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 SpringBoard"

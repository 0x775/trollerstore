ARCHS = arm64 arm64e
TARGET = iphone:clang:13.2:15.6
INSTALL_TARGET_PROCESSES = SpringBoard


include $(THEOS)/makefiles/common.mk

TWEAK_NAME = hookdemo

hookdemo_FILES = Tweak.x
hookdemo_CFLAGS = -fobjc-arc -Wno-deprecated-declarations -Wno-error=deprecated-declarations

hookdemo_FRAMEWORKS = UIKit Foundation QuartzCore CoreGraphics

include $(THEOS_MAKE_PATH)/tweak.mk

THEOS_PACKAGE_SCHEME = roothide
TARGET = iphone:clang:latest:15.0
ARCHS = arm64 arm64e
DEBUG = 0
FINALPACKAGE = 1

INSTALL_TARGET_PROCESSES = Preferences

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = CarrierLockedChangeToUnlocked

CarrierLockedChangeToUnlocked_FILES = Tweak.x
CarrierLockedChangeToUnlocked_CFLAGS = -fobjc-arc
CarrierLockedChangeToUnlocked_FRAMEWORKS = Foundation UIKit

include $(THEOS_MAKE_PATH)/tweak.mk

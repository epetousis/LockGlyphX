ARCHS = armv7 arm64
TARGET = iphone:clang:latest:10.0

include $(THEOS)/makefiles/common.mk

BUNDLE_NAME = LockGlyphXPrefs
LockGlyphXPrefs_FILES = LockGlyphXPrefs.mm
LockGlyphXPrefs_CFLAGS = -fobjc-arc
LockGlyphXPrefs_INSTALL_PATH = /Library/PreferenceBundles
LockGlyphXPrefs_FRAMEWORKS = UIKit CoreGraphics QuartzCore
LockGlyphXPrefs_PRIVATE_FRAMEWORKS = Preferences
LockGlyphXPrefs_LIBRARIES = colorpicker

include $(THEOS_MAKE_PATH)/bundle.mk

internal-stage::
	$(ECHO_NOTHING)mkdir -p $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences$(ECHO_END)
	$(ECHO_NOTHING)cp entry.plist $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences/LockGlyphXPrefs.plist$(ECHO_END)

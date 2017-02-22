ARCHS = armv7 arm64
TARGET = iphone:clang:9.2:10.0

include $(THEOS)/makefiles/common.mk

BUNDLE_NAME = LockGlyphX
LockGlyphX_FILES = LockGlyphXPrefs.mm
LockGlyphX_CFLAGS = -fobjc-arc
LockGlyphX_INSTALL_PATH = /Library/PreferenceBundles
LockGlyphX_FRAMEWORKS = UIKit CoreGraphics QuartzCore
LockGlyphX_PRIVATE_FRAMEWORKS = Preferences
LockGlyphX_LIBRARIES = colorpicker

include $(THEOS_MAKE_PATH)/bundle.mk

internal-stage::
	$(ECHO_NOTHING)mkdir -p $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences$(ECHO_END)
	$(ECHO_NOTHING)cp entry.plist $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences/LockGlyphX.plist$(ECHO_END)

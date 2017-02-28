ARCHS = armv7 arm64
TARGET = iphone:clang:10.2:10.0
# TARGET = simulator:clang

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = LockGlyphX
LockGlyphX_FILES = LockGlyphX.xm
LockGlyphX_CFLAGS = -fobjc-arc
LockGlyphX_FRAMEWORKS = UIKit CoreGraphics AudioToolbox AVFoundation QuartzCore
# LockGlyph_USE_SUBSTRATE = 0
include $(THEOS_MAKE_PATH)/tweak.mk

SUBPROJECTS += Prefs
include $(THEOS_MAKE_PATH)/aggregate.mk

after-install::
	install.exec "killall -9 backboardd"

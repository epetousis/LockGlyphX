#define kPreferencesFilePath @"/private/var/mobile/Library/Preferences/com.evilgoldfish.lockglyphx.plist"

NSDictionary *prefs;

static UIColor* parseColorFromPreferences(NSString* string) {
	NSArray *prefsarray = [string componentsSeparatedByString: @":"];
	NSString *hexString = [prefsarray objectAtIndex:0];
	double alpha = [[prefsarray objectAtIndex:1] doubleValue];

	unsigned rgbValue = 0;
    NSScanner *scanner = [NSScanner scannerWithString:hexString];
    [scanner setScanLocation:1]; // bypass '#' character
    [scanner scanHexInt:&rgbValue];
    return [[UIColor alloc] initWithRed:((rgbValue & 0xFF0000) >> 16)/255.0 green:((rgbValue & 0xFF00) >> 8)/255.0 blue:(rgbValue & 0xFF)/255.0 alpha:alpha];
}

static void loadPreferences(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
	if (prefs) {
		[prefs release];
	}
	prefs = [NSDictionary dictionaryWithContentsOfFile:kPreferencesFilePath];
}

static BOOL enabled(void) {
	//NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	BOOL enabled = [prefs objectForKey:@"enabled"] ? [[prefs objectForKey:@"enabled"] boolValue] : YES;
	//[pool release];
	return enabled;
}

static BOOL useUnlockSound(void) {
	//NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	BOOL useUnlockSound = [prefs objectForKey:@"useUnlockSound"] ? [[prefs objectForKey:@"useUnlockSound"] boolValue] : YES;
	//[pool release];
	return useUnlockSound;
}

static BOOL useTickAnimation(void) {
	//NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	BOOL useTickAnimation = [prefs objectForKey:@"useTickAnimation"] ? [[prefs objectForKey:@"useTickAnimation"] boolValue] : NO;
	//[pool release];
	return useTickAnimation;
}

static UIColor* primaryColor(void) {
	//NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	UIColor *primaryColor = [prefs objectForKey:@"primaryColor"] ? parseColorFromPreferences([prefs objectForKey:@"primaryColor"]) : [UIColor greenColor];
	//[pool release];
	return primaryColor;
}

static UIColor* secondaryColor(void) {
	//NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	UIColor *secondaryColor = [prefs objectForKey:@"secondaryColor"] ? parseColorFromPreferences([prefs objectForKey:@"secondaryColor"]) : [UIColor greenColor];
	//[pool release];
	return secondaryColor;
}

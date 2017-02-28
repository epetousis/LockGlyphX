//
//  LockGlyphX.xm
//  LockGlyphX
//
//  (c)2017 evilgoldfish
//
//  feat. @sticktron, @AppleBetasDev
//

#define DEBUG_PREFIX @"[LockGlyphX]"
#import "DebugLog.h"

#import "Headers.h"
#import "SpacemanBlocks.h"
#import "version.h"
#import <AudioToolbox/AudioServices.h>


#define kGlyphStateDefault 				0
#define kGlyphStateScanning 			1
#define kGlyphStateCustom 				(IS_IOS_OR_NEWER(iOS_10_2) ? 6 : 5)
#define kGlyphStateTicked 				(IS_IOS_OR_NEWER(iOS_10_2) ? 7 : 6)
#define kGlyphStateMovePhoneToReader 	(IS_IOS_OR_NEWER(iOS_10_2) ? 5 : 4)
#define kGlyphStateLoading 				(IS_IOS_OR_NEWER(iOS_10_2) ? 3 : 2)

#define kTouchIDFingerUp 	0
#define kTouchIDFingerDown 	1
#define kTouchIDFingerHeld 	2
#define kTouchIDMatched 	3
#define kTouchIDSuccess 	4
#define kTouchIDNotMatched 	10

#define kLockGlyphLockScreenActivatedNotification   @"LockGlyphLockScreenActivatedNotification"

#define kPrefsAppID 					CFSTR("com.evilgoldfish.lockglyphx")
#define kSettingsChangedNotification 	CFSTR("com.evilgoldfish.lockglyphx.settingschanged")

#define kThemePath 		@"/Library/Application Support/LockGlyph/Themes/"
#define kDefaultTheme 	@"Default.bundle"

#define kDefaultPrimaryColor 	[UIColor colorWithWhite:188/255.0f alpha:1] //#BCBCBC
#define kDefaultSecondaryColor 	[UIColor colorWithWhite:119/255.0f alpha:1] //#777777

#define kDefaultYOffset 					90.0f
#define kDefaultYOffsetWithLockLabelHidden 	64.0f

#define kSoundNone  		0
#define kSoundTheme 		1
#define kSoundApplePay 		2


@interface PKGlyphView (LockGlyphX)
- (void)addShineAnimation;
- (void)removeShineAnimation;
- (void)updatePositionWithOrientation:(UIInterfaceOrientation)orientation;
@end


static UIView *lockView;
static PKGlyphView *fingerglyph;
static SystemSoundID unlockSound;

static BOOL authenticated;
static BOOL usingDefaultGlyph;
static BOOL doingScanAnimation;
static BOOL doingTickAnimation;
static NSBundle *themeAssets;
SMDelayedBlockHandle unlockBlock;
static BOOL isObservingForCCCF;

static BOOL enabled;
static NSString *themeBundleName;
static int unlockSoundChoice;
static BOOL useTickAnimation;
static BOOL useLoadingStateForScanning;
static BOOL useHoldToReaderAnimation;
static BOOL useFasterAnimations;
static BOOL vibrateOnIncorrectFinger;
static BOOL shakeOnIncorrectFinger;
static BOOL useShine;
static BOOL shouldNotDelay;
static UIColor *primaryColor;
static UIColor *secondaryColor;
static BOOL enablePortraitY;
static CGFloat portraitY;
static BOOL enableLandscapeY;
static CGFloat landscapeY;
static BOOL enablePortraitX;
static CGFloat portraitX;
static BOOL enableLandscapeX;
static CGFloat landscapeX;
static BOOL shouldHideRing;
static NSString *pressHomeToUnlockText;
static BOOL hidePressHomeToUnlockLabel;
static BOOL overridePressHomeToUnlockText;

static UIColor *primaryColorOverride;
static UIColor *secondaryColorOverride;
static BOOL overrideIsForCustomCover;

static NSString *CFRevert = @"ColorFlowLockScreenColorReversionNotification";
static NSString *CFColor = @"ColorFlowLockScreenColorizationNotification";
static NSString *CCRevert = @"CustomCoverLockScreenColourResetNotification";
static NSString *CCColor = @"CustomCoverLockScreenColourUpdateNotification";

static CGFloat getDefaultYOffset() {
    return hidePressHomeToUnlockLabel ? kDefaultYOffsetWithLockLabelHidden : kDefaultYOffset;
}

static long long getIdleGlyphState() {
    return useHoldToReaderAnimation ? kGlyphStateMovePhoneToReader : kGlyphStateDefault;
}

static void setPrimaryColorOverride(UIColor *color) {
	if ([primaryColorOverride isEqual:color]) {
    	return;
	}
	primaryColorOverride = color;
}

static void setSecondaryColorOverride(UIColor *color) {
	if ([secondaryColorOverride isEqual:color]) {
		return;
	}
	secondaryColorOverride = color;
}

static UIColor *activePrimaryColor() {
	return primaryColorOverride ?: primaryColor;
}

static UIColor *activeSecondaryColor() {
	return secondaryColorOverride ?: secondaryColor;
}

static UIColor *parseColorFromPreferences(NSString* string) {
	NSArray *prefsarray = [string componentsSeparatedByString: @":"];
	NSString *hexString = [prefsarray objectAtIndex:0];
	double alpha = [[prefsarray objectAtIndex:1] doubleValue];
	
	unsigned rgbValue = 0;
	NSScanner *scanner = [NSScanner scannerWithString:hexString];
	[scanner setScanLocation:1]; // bypass '#' character
	[scanner scanHexInt:&rgbValue];
	
	return [UIColor colorWithRed:((rgbValue & 0xFF0000) >> 16)/255.0 green:((rgbValue & 0xFF00) >> 8)/255.0 blue:(rgbValue & 0xFF)/255.0 alpha:alpha];
}

static void loadPreferences() {
	CFPreferencesAppSynchronize(kPrefsAppID);
	enabled = !CFPreferencesCopyAppValue(CFSTR("enabled"), kPrefsAppID) ? YES : [CFBridgingRelease(CFPreferencesCopyAppValue(CFSTR("enabled"), kPrefsAppID)) boolValue];
	themeBundleName = !CFPreferencesCopyAppValue(CFSTR("currentTheme"), kPrefsAppID) ? kDefaultTheme : CFBridgingRelease(CFPreferencesCopyAppValue(CFSTR("currentTheme"), kPrefsAppID));
    unlockSoundChoice = !CFPreferencesCopyAppValue(CFSTR("unlockSound"), kPrefsAppID) ? kSoundTheme : [CFBridgingRelease(CFPreferencesCopyAppValue(CFSTR("unlockSound"), kPrefsAppID)) intValue];
	useTickAnimation = !CFPreferencesCopyAppValue(CFSTR("useTickAnimation"), kPrefsAppID) ? YES : [CFBridgingRelease(CFPreferencesCopyAppValue(CFSTR("useTickAnimation"), kPrefsAppID)) boolValue];
	useFasterAnimations = !CFPreferencesCopyAppValue(CFSTR("useFasterAnimations"), kPrefsAppID) ? NO : [CFBridgingRelease(CFPreferencesCopyAppValue(CFSTR("useFasterAnimations"), kPrefsAppID)) boolValue];
	vibrateOnIncorrectFinger = !CFPreferencesCopyAppValue(CFSTR("vibrateOnIncorrectFinger"), kPrefsAppID) ? YES : [CFBridgingRelease(CFPreferencesCopyAppValue(CFSTR("vibrateOnIncorrectFinger"), kPrefsAppID)) boolValue];
	shakeOnIncorrectFinger = !CFPreferencesCopyAppValue(CFSTR("shakeOnIncorrectFinger"), kPrefsAppID) ? YES : [CFBridgingRelease(CFPreferencesCopyAppValue(CFSTR("shakeOnIncorrectFinger"), kPrefsAppID)) boolValue];
	useShine = !CFPreferencesCopyAppValue(CFSTR("useShine"), kPrefsAppID) ? YES : [CFBridgingRelease(CFPreferencesCopyAppValue(CFSTR("useShine"), kPrefsAppID)) boolValue];
	shouldNotDelay = !CFPreferencesCopyAppValue(CFSTR("shouldNotDelay"), kPrefsAppID) ? NO : [CFBridgingRelease(CFPreferencesCopyAppValue(CFSTR("shouldNotDelay"), kPrefsAppID)) boolValue];
	primaryColor = !CFPreferencesCopyAppValue(CFSTR("primaryColor"), kPrefsAppID) ? kDefaultPrimaryColor : parseColorFromPreferences(CFBridgingRelease(CFPreferencesCopyAppValue(CFSTR("primaryColor"), kPrefsAppID)));
	secondaryColor = !CFPreferencesCopyAppValue(CFSTR("secondaryColor"), kPrefsAppID) ? kDefaultSecondaryColor : parseColorFromPreferences(CFBridgingRelease(CFPreferencesCopyAppValue(CFSTR("secondaryColor"), kPrefsAppID)));
	enablePortraitY = !CFPreferencesCopyAppValue(CFSTR("enablePortraitY"), kPrefsAppID) ? NO : [CFBridgingRelease(CFPreferencesCopyAppValue(CFSTR("enablePortraitY"), kPrefsAppID)) boolValue];
	portraitY = !CFPreferencesCopyAppValue(CFSTR("portraitY"), kPrefsAppID) ? 0 : [CFBridgingRelease(CFPreferencesCopyAppValue(CFSTR("portraitY"), kPrefsAppID)) floatValue];
	enableLandscapeY = !CFPreferencesCopyAppValue(CFSTR("enableLandscapeY"), kPrefsAppID) ? NO : [CFBridgingRelease(CFPreferencesCopyAppValue(CFSTR("enableLandscapeY"), kPrefsAppID)) boolValue];
	landscapeY = !CFPreferencesCopyAppValue(CFSTR("landscapeY"), kPrefsAppID) ? 0 : [CFBridgingRelease(CFPreferencesCopyAppValue(CFSTR("landscapeY"), kPrefsAppID)) floatValue];
	enablePortraitX = !CFPreferencesCopyAppValue(CFSTR("enablePortraitX"), kPrefsAppID) ? NO : [CFBridgingRelease(CFPreferencesCopyAppValue(CFSTR("enablePortraitX"), kPrefsAppID)) boolValue];
	portraitX = !CFPreferencesCopyAppValue(CFSTR("portraitX"), kPrefsAppID) ? 0 : [CFBridgingRelease(CFPreferencesCopyAppValue(CFSTR("portraitX"), kPrefsAppID)) floatValue];
	enableLandscapeX = !CFPreferencesCopyAppValue(CFSTR("enableLandscapeX"), kPrefsAppID) ? NO : [CFBridgingRelease(CFPreferencesCopyAppValue(CFSTR("enableLandscapeX"), kPrefsAppID)) boolValue];
	landscapeX = !CFPreferencesCopyAppValue(CFSTR("landscapeX"), kPrefsAppID) ? 0 : [CFBridgingRelease(CFPreferencesCopyAppValue(CFSTR("landscapeX"), kPrefsAppID)) floatValue];
	shouldHideRing = !CFPreferencesCopyAppValue(CFSTR("shouldHideRing"), kPrefsAppID) ? NO : [CFBridgingRelease(CFPreferencesCopyAppValue(CFSTR("shouldHideRing"), kPrefsAppID)) boolValue];
    hidePressHomeToUnlockLabel = !CFPreferencesCopyAppValue(CFSTR("hidePressHomeToUnlockLabel"), kPrefsAppID) ? YES : [CFBridgingRelease(CFPreferencesCopyAppValue(CFSTR("hidePressHomeToUnlockLabel"), kPrefsAppID)) boolValue];
    pressHomeToUnlockText = !CFPreferencesCopyAppValue(CFSTR("pressHomeToUnlockText"), kPrefsAppID) ? @"" : CFBridgingRelease(CFPreferencesCopyAppValue(CFSTR("pressHomeToUnlockText"), kPrefsAppID));
	overridePressHomeToUnlockText = !CFPreferencesCopyAppValue(CFSTR("overridePressHomeToUnlockText"), kPrefsAppID) ? NO : [CFBridgingRelease(CFPreferencesCopyAppValue(CFSTR("overridePressHomeToUnlockText"), kPrefsAppID)) boolValue];
    useLoadingStateForScanning = !CFPreferencesCopyAppValue(CFSTR("useLoadingStateForScanning"), kPrefsAppID) ? NO : [CFBridgingRelease(CFPreferencesCopyAppValue(CFSTR("useLoadingStateForScanning"), kPrefsAppID)) boolValue];
    useHoldToReaderAnimation = !CFPreferencesCopyAppValue(CFSTR("useHoldToReaderAnimation"), kPrefsAppID) ? NO : [CFBridgingRelease(CFPreferencesCopyAppValue(CFSTR("useHoldToReaderAnimation"), kPrefsAppID)) boolValue];
	
	// load theme bundle
	NSURL *bundleURL = [NSURL fileURLWithPath:kThemePath];
	themeAssets = [NSBundle bundleWithURL:[bundleURL URLByAppendingPathComponent:themeBundleName]];
	
	// dispose of old sound
	if (unlockSound) {
		AudioServicesDisposeSystemSoundID(unlockSound);
	}
	
	// load new sound
	if (unlockSoundChoice == kSoundTheme || unlockSoundChoice == kSoundApplePay) {
		NSURL *pathURL;
		
		if (unlockSoundChoice == kSoundTheme) {
		    if ([[NSFileManager defaultManager] fileExistsAtPath:[themeAssets pathForResource:@"SuccessSound" ofType:@"wav"]]) {
				// found theme sound
	            pathURL = [NSURL fileURLWithPath:[themeAssets pathForResource:@"SuccessSound" ofType:@"wav"]];
			}
		}
		
		// if we couldn't find a theme sound, or didn't want to use the theme sound, load the default sound
		if (!pathURL) {
			// use ApplePay sound
	        pathURL = [NSURL fileURLWithPath:@"/System/Library/Audio/UISounds/payment_success.caf"];
		}
		
		// create the new sound
		AudioServicesCreateSystemSoundID((__bridge CFURLRef)pathURL, &unlockSound);
	}
}

static void performFingerScanAnimation(void) {
	if (fingerglyph && [fingerglyph respondsToSelector:@selector(setState:animated:completionHandler:)]) {
		doingScanAnimation = YES;
        [fingerglyph setState:(useLoadingStateForScanning ? kGlyphStateLoading : kGlyphStateScanning) animated:YES completionHandler:^{
			doingScanAnimation = NO;
		}];
	}
}

static void resetFingerScanAnimation(void) {
    if (fingerglyph && [fingerglyph respondsToSelector:@selector(setState:animated:completionHandler:)]){
        if (fingerglyph.customImage)
            [fingerglyph setState:kGlyphStateCustom animated:YES completionHandler:nil];
        else
            [fingerglyph setState:getIdleGlyphState() animated:YES completionHandler:nil];
    }
}

// Reset finger scan without animation. I'll clean this up later
static void resetFingerScan(void) {
    if (fingerglyph && [fingerglyph respondsToSelector:@selector(setState:animated:completionHandler:)]){
        if (fingerglyph.customImage)
            [fingerglyph setState:kGlyphStateCustom animated:NO completionHandler:nil];
        else
            [fingerglyph setState:getIdleGlyphState() animated:NO completionHandler:nil];
    }
}

static void performTickAnimation(void) {
	if (fingerglyph) {
		doingTickAnimation = YES;
		[fingerglyph setState:kGlyphStateTicked animated:YES completionHandler:^{
			doingTickAnimation = NO;
		}];
	}
}

static void performShakeFingerFailAnimation(void) {
	if (fingerglyph) {
		CABasicAnimation *shakeanimation = [CABasicAnimation animationWithKeyPath:@"position"];
		[shakeanimation setDuration:0.05];
		[shakeanimation setRepeatCount:4];
		[shakeanimation setAutoreverses:YES];
		[shakeanimation setFromValue:[NSValue valueWithCGPoint:CGPointMake(fingerglyph.center.x - 10, fingerglyph.center.y)]];
		[shakeanimation setToValue:[NSValue valueWithCGPoint:CGPointMake(fingerglyph.center.x + 10, fingerglyph.center.y)]];
		[[fingerglyph layer] addAnimation:shakeanimation forKey:@"position"];
	}
}


//------------------------------------------------------------------------------

%hook SBDashBoardPageViewBase
- (void)didMoveToWindow {
	%orig;
	
	if (![self.pageViewController isKindOfClass:[%c(SBDashBoardMainPageViewController) class]]) {
		return;
	}
    
	// main page is leaving it's window, do some clean up
	if (!self.window) {
		[fingerglyph removeFromSuperview];
		fingerglyph = nil;
		
		// revert CustomCover override once we've been removed from the window
		if (overrideIsForCustomCover) {
			setPrimaryColorOverride(nil);
			setSecondaryColorOverride(nil);
		}
		
		return;
	}
	
	// We still need to send this if disabled so we can adjust accordingly in our other classes
    // [[NSNotificationCenter defaultCenter] postNotificationName:kLockGlyphLockScreenActivatedNotification object:nil];
	
	if (!enabled) {
		NSLog(@"LockGlyphX is disabled");
		return;
	}
	
	authenticated = NO;
	
	if (fingerglyph) {
		DebugLog(@"WARNING: fingerglyph shouldn't exist right now!");
		return;
	}
	
	// create the glyph
	fingerglyph = [[%c(PKGlyphView) alloc] initWithStyle:0];
	fingerglyph.delegate = (id<PKGlyphViewDelegate>)self;
	fingerglyph.primaryColor = activePrimaryColor();
	fingerglyph.secondaryColor = activeSecondaryColor();
	
	// check for theme
	if (themeAssets && ([[NSFileManager defaultManager] fileExistsAtPath:[themeAssets pathForResource:@"IdleImage" ofType:@"png"]] || [[NSFileManager defaultManager] fileExistsAtPath:[themeAssets pathForResource:@"IdleImage@2x" ofType:@"png"]])) {
		UIImage *customImage = [UIImage imageWithContentsOfFile:[themeAssets pathForResource:@"IdleImage" ofType:@"png"]];
		
		// set glyph to custom image mode
		[fingerglyph setCustomImage:customImage.CGImage withAlignmentEdgeInsets:UIEdgeInsetsZero];
		[fingerglyph setState:kGlyphStateCustom animated:NO completionHandler:nil];
		
		// resize the custom glyph to the size of the image?
		// CGRect frame = fingerglyph.frame;
		// frame.size = customImage.size;
		// fingerglyph.frame = frame;
		
		usingDefaultGlyph = NO;
	} else {
		[fingerglyph setState:getIdleGlyphState() animated:NO completionHandler:nil];
		usingDefaultGlyph = YES;
	}
	
	// set blend mode?
	// [fingerglyph _setDrawsAsBackdropOverlayWithBlendMode:kCGBlendModePlusDarker];
	// fingerglyph.tintColor = [UIColor colorWithWhite:0 alpha:0.50];
	
	// position glyph
	[fingerglyph updatePositionWithOrientation:[[UIApplication sharedApplication] statusBarOrientation]];
	
	// add shine animation
	if (useShine) {
		[fingerglyph addShineAnimation];
	} else {
		[fingerglyph removeShineAnimation];
	}
	
	// add tap recognizer to glyph
	UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(lockGlyphTapHandler:)];
	[fingerglyph addGestureRecognizer:tap];
		
	[self addSubview:fingerglyph];
	
	// listen for notifications from ColorFlow/CustomCover
	if (!isObservingForCCCF) {
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(LG_RevertUI:) name:CFRevert object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(LG_ColorizeUI:) name:CFColor object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(LG_RevertUI:) name:CCRevert object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(LG_ColorizeUI:) name:CCColor object:nil];
		isObservingForCCCF = YES;
	}
}
- (void)glyphView:(PKGlyphView *)arg1 revealingCheckmark:(BOOL)arg2 {
	DebugLog0;
	if (enabled && unlockSoundChoice != kSoundNone && useTickAnimation && unlockSound) {
		AudioServicesPlaySystemSound(unlockSound);
	}
}
- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	isObservingForCCCF = NO;
	%orig;
}
%new
- (void)lockGlyphTapHandler:(UITapGestureRecognizer *)recognizer {
	fingerglyph.userInteractionEnabled = NO;
	performFingerScanAnimation();
	
	if (!shouldNotDelay) {
		double delayInSeconds = 0.5;
		if (useFasterAnimations) {
			delayInSeconds = 0.4;
		}
		dispatch_after(dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC), dispatch_get_main_queue(), ^(void){
			if (useTickAnimation) {
				authenticated = YES;
				performTickAnimation();

				double delayInSeconds = 1.0;
				if (useFasterAnimations) {
					delayInSeconds = 0.4;
				}
				dispatch_after(dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC), dispatch_get_main_queue(), ^(void){
					if (!useTickAnimation && unlockSoundChoice != 0 && unlockSound) {
						AudioServicesPlaySystemSound(unlockSound);
					}
					authenticated = NO;
					[[%c(SBLockScreenManager) sharedInstance] unlockUIFromSource:2 withOptions:nil];
					resetFingerScanAnimation();
					fingerglyph.userInteractionEnabled = YES;
				});
			} else {
				[[%c(SBLockScreenManager) sharedInstance] unlockUIFromSource:2 withOptions:nil];
				resetFingerScanAnimation();
				fingerglyph.userInteractionEnabled = YES;
			}
		});
	} else {
		[[%c(SBLockScreenManager) sharedInstance] unlockUIFromSource:2 withOptions:nil];
		resetFingerScanAnimation();
		fingerglyph.userInteractionEnabled = YES;
	}
}
%new
- (void)LG_RevertUI:(NSNotification *)notification {
	setPrimaryColorOverride(nil);
	setSecondaryColorOverride(nil);
	if (enabled && usingDefaultGlyph && fingerglyph) {
		fingerglyph.primaryColor = activePrimaryColor();
		fingerglyph.secondaryColor = activeSecondaryColor();
	}
}
%new
- (void)LG_ColorizeUI:(NSNotification *)notification {
	NSDictionary *userInfo = [notification userInfo];
	UIColor *primaryColor;
	UIColor *secondaryColor;
	if([notification.name isEqualToString:@"ColorFlowLockScreenColorizationNotification"]) {
		primaryColor = userInfo[@"PrimaryColor"];
		secondaryColor = userInfo[@"SecondaryColor"];
		overrideIsForCustomCover = NO;
	}
	else if([notification.name isEqualToString:@"CustomCoverLockScreenColourUpdateNotification"]) {
		primaryColor = userInfo[@"PrimaryColour"];
		secondaryColor = userInfo[@"SecondaryColour"];
		overrideIsForCustomCover = YES;
	}
	setPrimaryColorOverride(primaryColor);
	setSecondaryColorOverride(secondaryColor);
	
	// if (enabled && usingDefaultGlyph && fingerglyph) {
	if (enabled && fingerglyph) {
		fingerglyph.primaryColor = activePrimaryColor();
		fingerglyph.secondaryColor = activeSecondaryColor();
	}
}
%end

//------------------------------------------------------------------------------

%hook PKGlyphView
%new
- (void)updatePositionWithOrientation:(UIInterfaceOrientation)orientation {
	CGRect screen = [[UIScreen mainScreen] bounds];
	float dx, dy;
	
	if (UIInterfaceOrientationIsLandscape(orientation)) {
		DebugLog(@"in landscape orientation");
		if (landscapeY == 0 || !enableLandscapeY) {
			dy = getDefaultYOffset();
		} else {
			dy = getDefaultYOffset() + landscapeY;
		}
		if (landscapeX == 0 || !enableLandscapeX) {
			dx = 0;
		} else {
			dx = landscapeX;
		}
		
	} else {
		DebugLog(@"in portrait orientation");
		if (portraitY == 0 || !enablePortraitY) {
			dy = getDefaultYOffset();
		} else {
			dy = getDefaultYOffset() + portraitY;
		}
		if (portraitX == 0 || !enablePortraitX) {
			dx = 0;
		} else {
			dx = portraitX;
		}
	}
	fingerglyph.center = CGPointMake(CGRectGetMidX(screen) + dx, screen.size.height - dy);
}
%new
- (void)addShineAnimation {
	/*
	 * Taken from this StackOverflow answer: http://stackoverflow.com/a/26081621
	 */
	CAGradientLayer *gradient = [CAGradientLayer layer];
	[gradient setStartPoint:CGPointMake(0, 0)];
	[gradient setEndPoint:CGPointMake(1, 0)];
	gradient.frame = CGRectMake(0, 0, self.bounds.size.width*3, self.bounds.size.height);
	float lowerAlpha = 0.78;
	gradient.colors = [NSArray arrayWithObjects:
					   (id)[[UIColor colorWithWhite:1 alpha:lowerAlpha] CGColor],
					   (id)[[UIColor colorWithWhite:1 alpha:lowerAlpha] CGColor],
					   (id)[[UIColor colorWithWhite:1 alpha:1.0] CGColor],
					   (id)[[UIColor colorWithWhite:1 alpha:1.0] CGColor],
					   (id)[[UIColor colorWithWhite:1 alpha:1.0] CGColor],
					   (id)[[UIColor colorWithWhite:1 alpha:lowerAlpha] CGColor],
					   (id)[[UIColor colorWithWhite:1 alpha:lowerAlpha] CGColor],
					   nil];
	gradient.locations = [NSArray arrayWithObjects:
						  [NSNumber numberWithFloat:0.0],
						  [NSNumber numberWithFloat:0.4],
						  [NSNumber numberWithFloat:0.45],
						  [NSNumber numberWithFloat:0.5],
						  [NSNumber numberWithFloat:0.55],
						  [NSNumber numberWithFloat:0.6],
						  [NSNumber numberWithFloat:1.0],
						  nil];

	CABasicAnimation *theAnimation;
	theAnimation=[CABasicAnimation animationWithKeyPath:@"transform.translation.x"];
	theAnimation.duration = 2;
	theAnimation.repeatCount = INFINITY;
	theAnimation.autoreverses = NO;
	theAnimation.removedOnCompletion = NO;
	theAnimation.fillMode = kCAFillModeForwards;
	theAnimation.fromValue=[NSNumber numberWithFloat:-self.frame.size.width*2];
	theAnimation.toValue=[NSNumber numberWithFloat:0];
	[gradient addAnimation:theAnimation forKey:@"animateLayer"];

	self.layer.mask = gradient;
}
%new
- (void)removeShineAnimation {
	self.layer.mask = nil;
}
- (id)createCustomImageLayer {
	CALayer *result = %orig;
	if (enabled) {
		result.contentsScale = 2.0;
		result.mask = nil;
	}
	return result;
}
- (void)_layoutContentLayer:(id)arg1 {
	%orig;
	
	// if (!usingDefaultGlyph) {
	// 	self.clipsToBounds = YES;
	// } else {
	// 	self.clipsToBounds = NO;
	// }
}
%end

//------------------------------------------------------------------------------

/* iOS 10.2 */
%hook PKFingerprintGlyphView
- (void)_setProgress:(double)arg1 withDuration:(double)arg2 forShapeLayerAtIndex:(unsigned long long)arg {
	if (enabled && useFasterAnimations && usingDefaultGlyph && (doingTickAnimation || doingScanAnimation)) {
		if (authenticated) {
			arg2 = MIN(arg2, 0.1);
		} else {
			arg1 = MIN(arg1, 0.8);
			arg2 *= 0.5;
		}
	}
	%orig;
}
- (double)_minimumAnimationDurationForStateTransition {
	return enabled && authenticated && useFasterAnimations && (doingTickAnimation || doingScanAnimation) ? 0.1 : %orig;
}
- (void)layoutSubviews {
	%orig;
	
	if (enabled && shouldHideRing) {
		CALayer *ringLayer = MSHookIvar<CALayer *>(self, "_foregroundRingContainerLayer");
		ringLayer.hidden = YES;
	}
}
%end

/* iOS 10, 10.1 */
%hook PKSubglyphView
- (void)_setProgress:(double)arg1 withDuration:(double)arg2 forShapeLayerAtIndex:(unsigned long long)arg {
	if (enabled && useFasterAnimations && usingDefaultGlyph && (doingTickAnimation || doingScanAnimation)) {
		if (authenticated) {
			arg2 = MIN(arg2, 0.1);
		} else {
			arg1 = MIN(arg1, 0.8);
			arg2 *= 0.5;
		}
	}
	%orig;
}
- (double)_minimumAnimationDurationForStateTransition {
	return enabled && authenticated && useFasterAnimations && (doingTickAnimation || doingScanAnimation) ? 0.1 : %orig;
}
- (void)layoutSubviews {
	%orig;
	
	if (enabled && shouldHideRing) {
		CALayer *ringLayer = MSHookIvar<CALayer *>(self, "_foregroundRingContainerLayer");
		ringLayer.hidden = YES;
	}
}
%end

//------------------------------------------------------------------------------

%hook SBDashBoardMesaUnlockBehavior

/* iOS 10.2 */
- (void)handleBiometricEvent:(unsigned long long)event {
	if (!enabled || authenticated) {
		%orig;
		return;
	}
	
	SBLockScreenManager *manager = [%c(SBLockScreenManager) sharedInstance];
	if ([manager isUILocked]) {
		DebugLog(@"Biometric event occured: %llu", event);
		
		switch (event) {
			case kTouchIDFingerDown:
				DebugLog(@"TouchID: finger down");
				performFingerScanAnimation();
			break;
				
			case kTouchIDFingerUp:
				DebugLog(@"TouchID: finger up");
				resetFingerScanAnimation();
			break;
				
			case kTouchIDNotMatched:
				DebugLog(@"TouchID: match failed");
				if (shakeOnIncorrectFinger) {
					performShakeFingerFailAnimation();
				}
				if (vibrateOnIncorrectFinger && ![manager.lockScreenViewController isPasscodeLockVisible]) {
					AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
				}
			break;
				
			case kTouchIDSuccess:
				DebugLog(@"TouchID: success");
				
				authenticated = YES;
				
				if ([%c(SBAssistantController) isAssistantVisible] || manager.bioAuthenticatedWhileMenuButtonDown) {
					DebugLog(@"isAssistantVisible || bioAuthenticatedWhileMenuButtonDown");
					if (unlockBlock) {
						cancel_delayed_block(unlockBlock);
					}
					return %orig;
				}
				
				if (!shouldNotDelay && ![manager.lockScreenViewController isPasscodeLockVisible]) {
					DebugLog(@"!shouldNotDelay && !passcodeVisible");
					
					fingerglyph.userInteractionEnabled = NO;
					performTickAnimation();
					
					double delayInSeconds = 1.3;
					if (!useTickAnimation) {
						delayInSeconds = 0.3;
					}
					if (useFasterAnimations) {
						delayInSeconds = 0.5;
						if (!useTickAnimation) {
							delayInSeconds = 0.1;
						}
					}
					
					unlockBlock = perform_block_after_delay(delayInSeconds, ^(void){
						DebugLog(@"performing block after delay now");
						if (!useTickAnimation && unlockSoundChoice != kSoundNone && unlockSound) {
							AudioServicesPlaySystemSound(unlockSound);
						}
						%orig;
					});
					
				} else {
					if (manager.bioAuthenticatedWhileMenuButtonDown) {
						DebugLog(@"bioAuthenticatedWhileMenuButtonDown");
						return %orig;
					}
					if (!manager.isUILocked) {
						DebugLog(@"manager.isUILocked == NO");
						if (!useTickAnimation && unlockSoundChoice != kSoundNone && unlockSound && shouldNotDelay) {
							DebugLog(@"!useTickAnimation && unlockSoundChoice != 0 && unlockSound && shouldNotDelay");
							AudioServicesPlaySystemSound(unlockSound);
						}
					}
					return %orig;
				}
			break;
		}
	}
}

/* iOS 10, 10.1 */
- (void)biometricEventMonitor:(id)arg1 handleBiometricEvent:(unsigned long long)event {
	if (!enabled || authenticated) {
		%orig;
		return;
	}
	
	SBLockScreenManager *manager = [%c(SBLockScreenManager) sharedInstance];
	if ([manager isUILocked]) {
		DebugLog(@"Biometric event occured: %llu", event);
		
		switch (event) {
			case kTouchIDFingerDown:
				DebugLog(@"TouchID: finger down");
				performFingerScanAnimation();
			break;
				
			case kTouchIDFingerUp:
				DebugLog(@"TouchID: finger up");
				resetFingerScanAnimation();
			break;
				
			case kTouchIDNotMatched:
				DebugLog(@"TouchID: match failed");
				if (shakeOnIncorrectFinger) {
					performShakeFingerFailAnimation();
				}
				if (vibrateOnIncorrectFinger) {
					AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
				}
			break;
				
			case kTouchIDSuccess:
				DebugLog(@"TouchID: success");
				
				authenticated = YES;
				
				if ([%c(SBAssistantController) isAssistantVisible] || manager.bioAuthenticatedWhileMenuButtonDown) {
					DebugLog(@"isAssistantVisible || bioAuthenticatedWhileMenuButtonDown");
					if (unlockBlock) {
						cancel_delayed_block(unlockBlock);
					}
					return %orig;
				}
				
				if (!shouldNotDelay && ![manager.lockScreenViewController isPasscodeLockVisible]) {
					DebugLog(@"!shouldNotDelay && !passcodeVisible");
					
					fingerglyph.userInteractionEnabled = NO;
					performTickAnimation();
					
					double delayInSeconds = 1.3;
					if (!useTickAnimation) {
						delayInSeconds = 0.3;
					}
					if (useFasterAnimations) {
						delayInSeconds = 0.5;
						if (!useTickAnimation) {
							delayInSeconds = 0.1;
						}
					}
					
					unlockBlock = perform_block_after_delay(delayInSeconds, ^(void){
						DebugLog(@"performing block after delay now");
						if (!useTickAnimation && unlockSoundChoice != kSoundNone && unlockSound) {
							AudioServicesPlaySystemSound(unlockSound);
						}
						%orig;
					});
					
				} else {
					if (manager.bioAuthenticatedWhileMenuButtonDown) {
						DebugLog(@"bioAuthenticatedWhileMenuButtonDown");
						return %orig;
					}
					if (!manager.isUILocked) {
						DebugLog(@"manager.isUILocked == NO");
						if (!useTickAnimation && unlockSoundChoice != kSoundNone && unlockSound && shouldNotDelay) {
							DebugLog(@"!useTickAnimation && unlockSoundChoice != 0 && unlockSound && shouldNotDelay");
							AudioServicesPlaySystemSound(unlockSound);
						}
					}
					return %orig;
				}
			break;
		}
	}
}

%end

//------------------------------------------------------------------------------

%hook SBDashBoardViewController
- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)orientation duration:(NSTimeInterval)duration {
	%orig;
	if (enabled) [fingerglyph updatePositionWithOrientation:orientation];
}
- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)orientation duration:(NSTimeInterval)duration {
	%orig;
	if (enabled) {
		[UIView animateWithDuration:duration
							  delay:0
							options:UIViewAnimationOptionCurveLinear
						 animations:^(void) { [fingerglyph updatePositionWithOrientation:orientation]; }
						 completion:nil];
	}
}
- (void)setAuthenticated:(BOOL)arg1 {
    %orig;
    if (enabled && !arg1) {
        authenticated = NO;
        resetFingerScan();
    }
}
%end

//------------------------------------------------------------------------------

%hook SBLockScreenViewController
- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
	%orig;
	if (enabled) {
		[UIView animateWithDuration:duration
							  delay:0
							options:UIViewAnimationOptionCurveLinear
						 animations:^(void) { [fingerglyph updatePositionWithOrientation:toInterfaceOrientation]; }
						 completion:nil];
	}
}
%end

//------------------------------------------------------------------------------

%hook SBAssistantController
- (void)_viewWillDisappearOnMainScreen:(BOOL)arg1 {
	if (enabled && fingerglyph) {
		resetFingerScanAnimation();
	}
	%orig;
}
- (void)_viewDidDisappearOnMainScreen:(BOOL)arg1 {
	if (enabled && fingerglyph) {
		resetFingerScanAnimation();
	}
	%orig;
}
%end

//------------------------------------------------------------------------------

%hook SBUICallToActionLabel
- (void)setText:(id)text {
	if (enabled && hidePressHomeToUnlockLabel) {
		text = @"";
	} else if (enabled && !authenticated && overridePressHomeToUnlockText && ![pressHomeToUnlockText isEqualToString:@""]) {
        text = pressHomeToUnlockText;
    }
	%orig;
}
- (void)setText:(id)text forLanguage:(id)language animated:(BOOL)animated {
	if (enabled && hidePressHomeToUnlockLabel) {
		text = @"";
	} else if (enabled && !authenticated && overridePressHomeToUnlockText && ![pressHomeToUnlockText isEqualToString:@""]) {
        text = pressHomeToUnlockText;
    }
	%orig;
}
%end

//------------------------------------------------------------------------------

%ctor {
	@autoreleasepool {
		NSLog(@"LockGlyphX was here.");
		
		loadPreferences();
		
		CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(),
			NULL,
			(CFNotificationCallback)loadPreferences,
			kSettingsChangedNotification,
			NULL,
			CFNotificationSuspensionBehaviorDeliverImmediately
		);
	}
}

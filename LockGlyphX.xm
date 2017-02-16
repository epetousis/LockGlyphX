//
//  LockGlyphX.xm
//  LockGlyphX
//
//  evilgoldfish feat. sticktron 2017
//

#import "LockGlyphX.h"
#import "SpacemanBlocks.h"
#import "Headers/PKGlyphView.h"
#import <AudioToolbox/AudioServices.h>


#define kGlyphStateDefault 	0
#define kGlyphStateScanning	1
#define kGlyphStateCustom	6
#define kGlyphStateTicked	7

#define kTouchIDFingerUp 	0
#define kTouchIDFingerDown  1
#define kTouchIDFingerHeld  2
#define kTouchIDMatched 	3
#define kTouchIDSuccess 	4
#define kTouchIDNotMatched 	10

#define kBundlePath @"/Library/Application Support/LockGlyph/Themes/"

#define kDefaultPrimaryColor 	[UIColor colorWithWhite:188/255.0f alpha:1] //#BCBCBC
#define kDefaultSecondaryColor 	[UIColor colorWithWhite:119/255.0f alpha:1] //#777777

#define kDefaultYOffset 100.0f

static UIView *lockView;
static PKGlyphView *fingerglyph;
static SystemSoundID unlockSound;

static BOOL authenticated;
static BOOL usingGlyph;
static BOOL doingScanAnimation;
static BOOL doingTickAnimation;
static NSBundle *themeAssets;
SMDelayedBlockHandle unlockBlock;

static BOOL enabled;
static BOOL useUnlockSound;
static BOOL useTickAnimation;
static BOOL useFasterAnimations;
static BOOL vibrateOnIncorrectFinger;
static BOOL shakeOnIncorrectFinger;
static BOOL useShine;
static UIColor *primaryColor;
static UIColor *secondaryColor;
static BOOL enablePortraitY;
static CGFloat portraitY;
static BOOL enableLandscapeY;
static CGFloat landscapeY;
static NSString *themeBundleName;
static BOOL shouldNotDelay;

static UIColor *primaryColorOverride;
static UIColor *secondaryColorOverride;
static BOOL overrideIsForCustomCover;


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
static UIColor * activePrimaryColor() {
  return primaryColorOverride ?: primaryColor;
}
static UIColor * activeSecondaryColor() {
  return secondaryColorOverride ?: secondaryColor;
}
static UIColor * parseColorFromPreferences(NSString* string) {
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
	CFPreferencesAppSynchronize(CFSTR("com.evilgoldfish.lockglyphx"));
	enabled = !CFPreferencesCopyAppValue(CFSTR("enabled"), CFSTR("com.evilgoldfish.lockglyphxx")) ? YES : [(__bridge id)CFPreferencesCopyAppValue(CFSTR("enabled"), CFSTR("com.evilgoldfish.lockglyphxx")) boolValue];
	useUnlockSound = !CFPreferencesCopyAppValue(CFSTR("useUnlockSound"), CFSTR("com.evilgoldfish.lockglyphxx")) ? YES : [(__bridge id)CFPreferencesCopyAppValue(CFSTR("useUnlockSound"), CFSTR("com.evilgoldfish.lockglyphx")) boolValue];
	useTickAnimation = !CFPreferencesCopyAppValue(CFSTR("useTickAnimation"), CFSTR("com.evilgoldfish.lockglyphx")) ? YES : [(__bridge id)CFPreferencesCopyAppValue(CFSTR("useTickAnimation"), CFSTR("com.evilgoldfish.lockglyphx")) boolValue];
	useFasterAnimations = !CFPreferencesCopyAppValue(CFSTR("useFasterAnimations"), CFSTR("com.evilgoldfish.lockglyphx")) ? NO : [(__bridge id)CFPreferencesCopyAppValue(CFSTR("useFasterAnimations"), CFSTR("com.evilgoldfish.lockglyphx")) boolValue];
	vibrateOnIncorrectFinger = !CFPreferencesCopyAppValue(CFSTR("vibrateOnIncorrectFinger"), CFSTR("com.evilgoldfish.lockglyphx")) ? YES : [(__bridge id)CFPreferencesCopyAppValue(CFSTR("vibrateOnIncorrectFinger"), CFSTR("com.evilgoldfish.lockglyphx")) boolValue];
	shakeOnIncorrectFinger = !CFPreferencesCopyAppValue(CFSTR("shakeOnIncorrectFinger"), CFSTR("com.evilgoldfish.lockglyphx")) ? YES : [(__bridge id)CFPreferencesCopyAppValue(CFSTR("shakeOnIncorrectFinger"), CFSTR("com.evilgoldfish.lockglyphx")) boolValue];
	useShine = !CFPreferencesCopyAppValue(CFSTR("useShine"), CFSTR("com.evilgoldfish.lockglyphx")) ? YES : [(__bridge id)CFPreferencesCopyAppValue(CFSTR("useShine"), CFSTR("com.evilgoldfish.lockglyphx")) boolValue];
	primaryColor = !CFPreferencesCopyAppValue(CFSTR("primaryColor"), CFSTR("com.evilgoldfish.lockglyphx")) ? kDefaultPrimaryColor : parseColorFromPreferences((__bridge id)CFPreferencesCopyAppValue(CFSTR("primaryColor"), CFSTR("com.evilgoldfish.lockglyphx")));
	secondaryColor = !CFPreferencesCopyAppValue(CFSTR("secondaryColor"), CFSTR("com.evilgoldfish.lockglyphx")) ? kDefaultSecondaryColor : parseColorFromPreferences((__bridge id)CFPreferencesCopyAppValue(CFSTR("secondaryColor"), CFSTR("com.evilgoldfish.lockglyphx")));
	enablePortraitY = !CFPreferencesCopyAppValue(CFSTR("enablePortraitY"), CFSTR("com.evilgoldfish.lockglyphx")) ? NO : [(__bridge id)CFPreferencesCopyAppValue(CFSTR("enablePortraitY"), CFSTR("com.evilgoldfish.lockglyphx")) boolValue];
	portraitY = !CFPreferencesCopyAppValue(CFSTR("portraitY"), CFSTR("com.evilgoldfish.lockglyphx")) ? 0 : [(__bridge id)CFPreferencesCopyAppValue(CFSTR("portraitY"), CFSTR("com.evilgoldfish.lockglyphx")) floatValue];
	enableLandscapeY = !CFPreferencesCopyAppValue(CFSTR("enableLandscapeY"), CFSTR("com.evilgoldfish.lockglyphx")) ? NO : [(__bridge id)CFPreferencesCopyAppValue(CFSTR("enableLandscapeY"), CFSTR("com.evilgoldfish.lockglyphx")) boolValue];
	landscapeY = !CFPreferencesCopyAppValue(CFSTR("landscapeY"), CFSTR("com.evilgoldfish.lockglyphx")) ? 0 : [(__bridge id)CFPreferencesCopyAppValue(CFSTR("landscapeY"), CFSTR("com.evilgoldfish.lockglyphx")) floatValue];
	themeBundleName = !CFPreferencesCopyAppValue(CFSTR("currentTheme"), CFSTR("com.evilgoldfish.lockglyphx")) ? @"LockGlyph-Default.bundle" : (__bridge id)CFPreferencesCopyAppValue(CFSTR("currentTheme"), CFSTR("com.evilgoldfish.lockglyphx"));
	shouldNotDelay = !CFPreferencesCopyAppValue(CFSTR("shouldNotDelay"), CFSTR("com.evilgoldfish.lockglyphx")) ? NO : [(__bridge id)CFPreferencesCopyAppValue(CFSTR("shouldNotDelay"), CFSTR("com.evilgoldfish.lockglyphx")) boolValue];
	
	// load theme assets
	NSURL *bundleURL = [NSURL fileURLWithPath:kBundlePath];
	themeAssets = [NSBundle bundleWithURL:[bundleURL URLByAppendingPathComponent:themeBundleName]];
	HBLogDebug(@"found assets for theme (%@): %@", themeBundleName, themeAssets);
	
	// load sound
	if (unlockSound) {
		AudioServicesDisposeSystemSoundID(unlockSound);
	}
	if ([[NSFileManager defaultManager] fileExistsAtPath:[themeAssets pathForResource:@"SuccessSound" ofType:@"wav"]]) {
		HBLogDebug(@"found sound for theme");
		NSURL *pathURL = [NSURL fileURLWithPath:[themeAssets pathForResource:@"SuccessSound" ofType:@"wav"]];
		AudioServicesCreateSystemSoundID((__bridge CFURLRef) pathURL, &unlockSound);
	} else {
		HBLogDebug(@"no sound for theme, using default");
		NSURL *pathURL = [NSURL fileURLWithPath:@"/Library/Application Support/LockGlyph/Themes/LockGlyph-Default.bundle/SuccessSound.wav"];
		AudioServicesCreateSystemSoundID((__bridge CFURLRef) pathURL, &unlockSound);
	}
}

static void performFingerScanAnimation(void) {
	if (fingerglyph && [fingerglyph respondsToSelector:@selector(setState:animated:completionHandler:)]) {
		doingScanAnimation = YES;
		[fingerglyph setState:kGlyphStateScanning animated:YES completionHandler:^{
			doingScanAnimation = NO;
		}];
	}
}
static void resetFingerScanAnimation(void) {
	if (fingerglyph && [fingerglyph respondsToSelector:@selector(setState:animated:completionHandler:)]){
		if (fingerglyph.customImage)
			[fingerglyph setState:kGlyphStateCustom animated:YES completionHandler:nil];
		else
			[fingerglyph setState:kGlyphStateDefault animated:YES completionHandler:nil];
	}
}
static void performTickAnimation(void) {
	if (fingerglyph && [fingerglyph respondsToSelector:@selector(setState:animated:completionHandler:)]) {
		doingTickAnimation = YES;
		[fingerglyph setState:kGlyphStateTicked animated:YES completionHandler:^{
			doingTickAnimation = NO;
			fingerglyph = nil;
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

// NEW: 'CUSTOM UNLOCK TEXT'
%hook SBUICallToActionLabel
- (void)setText:(id)arg1 forLanguage:(id)arg2 animated:(_Bool)arg3 {
	%orig(@"LockGlyphX", arg2, arg3);
}
%end

//------------------------------------------------------------------------------

@interface SBDashBoardMainPageView (LockGlyphX)
- (void)addShineAnimationToView:(UIView *)aView;
@end

%hook SBDashBoardMainPageView

- (void)didMoveToWindow {
	if (!self.window) {
		fingerglyph = nil;
		
		// Fix to revert CustomCover override once we've been removed from the window.
		if (overrideIsForCustomCover) {
			setPrimaryColorOverride(nil);
			setSecondaryColorOverride(nil);
		}
		return;
	}
	
	if (enabled) {
		// So we don't receive multiple notifications from over registering.
	// 	NSString *CFRevert = @"ColorFlowLockScreenColorReversionNotification";
	// 	NSString *CFColor = @"ColorFlowLockScreenColorizationNotification";
	// 	NSString *CCRevert = @"CustomCoverLockScreenColourResetNotification";
	// 	NSString *CCColor = @"CustomCoverLockScreenColourUpdateNotification";
	// 	[[NSNotificationCenter defaultCenter] removeObserver:self name:CFRevert object:nil];
	// 	[[NSNotificationCenter defaultCenter] removeObserver:self name:CFColor object:nil];
	// 	[[NSNotificationCenter defaultCenter] removeObserver:self name:CCRevert object:nil];
	// 	[[NSNotificationCenter defaultCenter] removeObserver:self name:CCColor object:nil];
	// 	[[NSNotificationCenter defaultCenter] addObserver:self
	// 										 selector:@selector(LG_RevertUI:)
	// 											 name:CFRevert
	// 										   object:nil];
	// 	[[NSNotificationCenter defaultCenter] addObserver:self
	// 											 selector:@selector(LG_ColorizeUI:)
	// 												 name:CFColor
	// 											   object:nil];
	//    [[NSNotificationCenter defaultCenter] addObserver:self
	// 										selector:@selector(LG_RevertUI:)
	// 											name:CCRevert
	// 										  object:nil];
	//    [[NSNotificationCenter defaultCenter] addObserver:self
	// 											selector:@selector(LG_ColorizeUI:)
	// 												name:CCColor
	// 											  object:nil];
	
		lockView = (UIView *)self;
		authenticated = NO;
		usingGlyph = YES;
		
		fingerglyph = [[%c(PKGlyphView) alloc] initWithStyle:0];
		fingerglyph.delegate = (id<PKGlyphViewDelegate>)self;
		fingerglyph.primaryColor = activePrimaryColor();
		fingerglyph.secondaryColor = activeSecondaryColor();
		
		// NEW FEATURE? 'BLEND MODE' -------------------------------------------
		// [fingerglyph _setDrawsAsBackdropOverlayWithBlendMode:kCGBlendModePlusDarker];
		// fingerglyph.tintColor = [UIColor colorWithWhite:0 alpha:0.65];
		
		// setup custom glyph
		if (themeAssets && ([[NSFileManager defaultManager] fileExistsAtPath:[themeAssets pathForResource:@"IdleImage" ofType:@"png"]] || [[NSFileManager defaultManager] fileExistsAtPath:[themeAssets pathForResource:@"IdleImage@2x" ofType:@"png"]])) {
			HBLogDebug(@"found theme glyph");
			UIImage *customImage = [UIImage imageWithContentsOfFile:[themeAssets pathForResource:@"IdleImage" ofType:@"png"]];
			// CGImage *customCGImage = [UIImage imageWithCGImage:customImage.CGImage scale:[UIScreen mainScreen].scale orientation:customImage.imageOrientation].CGImage;
			CGImage *customCGImage = [UIImage imageWithCGImage:customImage.CGImage scale:2 orientation:customImage.imageOrientation].CGImage;
			[fingerglyph setCustomImage:customCGImage withAlignmentEdgeInsets:UIEdgeInsetsZero];
			
			// set glyph to custom mode
			[fingerglyph setState:kGlyphStateCustom animated:YES completionHandler:nil];
			
		} else {
			// fingerglyph.customImage = nil;
			[fingerglyph setCustomImage:nil withAlignmentEdgeInsets:UIEdgeInsetsZero];
		}
		
		// position glyph
		CGRect screen = [[UIScreen mainScreen] bounds];
		HBLogDebug(@"screen size = %@", NSStringFromCGRect(screen));
		if (UIInterfaceOrientationIsLandscape([[UIApplication sharedApplication] statusBarOrientation])) {
			HBLogDebug(@"in landscape orientation");
			if (landscapeY == 0 || !enableLandscapeY) {
				fingerglyph.center = CGPointMake(CGRectGetMidX(screen), screen.size.height - kDefaultYOffset);
			} else {
				fingerglyph.center = CGPointMake(CGRectGetMidY(screen), landscapeY);
			}
		} else {
			HBLogDebug(@"in portrait orientation");
			if (portraitY == 0 || !enablePortraitY) {
				fingerglyph.center = CGPointMake(CGRectGetMidX(screen), screen.size.height - kDefaultYOffset);
			} else {
				fingerglyph.center = CGPointMake(CGRectGetMidX(screen), portraitY);
			}
		}
		HBLogDebug(@"fingerglyph.frame = %@", NSStringFromCGRect(fingerglyph.frame));
		
		// add shine animation
		if (useShine) {
			[self addShineAnimationToView:fingerglyph];
		}
		
		// add tap recognizer
		UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(lockGlyphTapHandler:)];
		[fingerglyph addGestureRecognizer:tap];
		
		// hide slide-top-unlock view (CRASHES)
		// [[[[%c(SBLockScreenManager) sharedInstance] lockScreenViewController] lockScreenView] setSlideToUnlockHidden:YES forRequester:@"com.evilgoldfish.lockglyph"];
		
		[self addSubview:fingerglyph];
	}
}

/* Taken from this StackOverflow answer: http://stackoverflow.com/a/26081621 */
%new
- (void)addShineAnimationToView:(UIView*)aView {
	CAGradientLayer *gradient = [CAGradientLayer layer];
	[gradient setStartPoint:CGPointMake(0, 0)];
	[gradient setEndPoint:CGPointMake(1, 0)];
	gradient.frame = CGRectMake(0, 0, aView.bounds.size.width*3, aView.bounds.size.height);
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
	theAnimation.fromValue=[NSNumber numberWithFloat:-aView.frame.size.width*2];
	theAnimation.toValue=[NSNumber numberWithFloat:0];
	[gradient addAnimation:theAnimation forKey:@"animateLayer"];

	aView.layer.mask = gradient;
}

%new
- (void)lockGlyphTapHandler:(UITapGestureRecognizer *)recognizer {
	HBLogDebug(@"glyph was tapped");
	performFingerScanAnimation();
	fingerglyph.userInteractionEnabled = NO;
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
					if (!useTickAnimation && useUnlockSound && unlockSound) {
						AudioServicesPlaySystemSound(unlockSound);
					}
					authenticated = NO;
					// [[%c(SBLockScreenManager) sharedInstance] unlockUIFromSource:0 withOptions:nil];
					[[%c(SBLockScreenManager) sharedInstance] unlockUIFromSource:2 withOptions:nil];
					resetFingerScanAnimation();
					fingerglyph.userInteractionEnabled = YES;
				});
			} else {
				// [[%c(SBLockScreenManager) sharedInstance] unlockUIFromSource:0 withOptions:nil];
				[[%c(SBLockScreenManager) sharedInstance] unlockUIFromSource:2 withOptions:nil];
				resetFingerScanAnimation();
				fingerglyph.userInteractionEnabled = YES;
			}
		});
	} else {
		// [[%c(SBLockScreenManager) sharedInstance] unlockUIFromSource:0 withOptions:nil];
		[[%c(SBLockScreenManager) sharedInstance] unlockUIFromSource:2 withOptions:nil];
		resetFingerScanAnimation();
		fingerglyph.userInteractionEnabled = YES;
	}
}

/*
%new
- (void)LG_RevertUI:(NSNotification *)notification {
	setPrimaryColorOverride(nil);
	setSecondaryColorOverride(nil);
	if (enabled && usingGlyph && fingerglyph) {
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
	if (enabled && usingGlyph && fingerglyph) {
		fingerglyph.primaryColor = activePrimaryColor();
		fingerglyph.secondaryColor = activeSecondaryColor();
	}
}
*/

// %new(v@:@c)
// - (void)glyphView:(PKGlyphView *)arg1 revealingCheckmark:(BOOL)arg2 {
// 	if (useUnlockSound && useTickAnimation && unlockSound) {
// 		AudioServicesPlaySystemSound(unlockSound);
// 	}
// }

- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	%orig;
}

%end

//------------------------------------------------------------------------------

%hook PKFingerprintGlyphView

/*
- (void)_setProgress:(double)arg1 withDuration:(double)arg2 forShapeLayerAtIndex:(unsigned long long)arg {
	if (lockView && enabled && useFasterAnimations && usingGlyph && (doingTickAnimation || doingScanAnimation)) {
		if (authenticated) {
			arg2 = MIN(arg2, 0.1);
		} else {
			arg1 = MIN(arg1, 0.8);
			arg2 *= 0.5;
		}
	}
	%orig;
}
*/

/*
- (double)_minimumAnimationDurationForStateTransition {
	return authenticated && useFasterAnimations && usingGlyph && (doingTickAnimation || doingScanAnimation) ? 0.1 : %orig;
}
*/

%end

//------------------------------------------------------------------------------

%hook SBLockScreenManager

- (void)_bioAuthenticated:(id)arg1 {
	HBLogDebug(@"SBLockScreenManager::_bioAuthenticated: (%@)", arg1);
	
	if ([%c(SBAssistantController) isAssistantVisible] || self.bioAuthenticatedWhileMenuButtonDown) {
	// 	if (unlockBlock) {
	// 		cancel_delayed_block(unlockBlock);
	// 	}
		return;
	}
	
	if (lockView && self.isUILocked && enabled && !authenticated && !shouldNotDelay && ![[self lockScreenViewController] isPasscodeLockVisible]) {
		fingerglyph.userInteractionEnabled = NO;
		authenticated = YES;
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
			if (!useTickAnimation && useUnlockSound && unlockSound) {
				AudioServicesPlaySystemSound(unlockSound);
			}
			if (fingerglyph) {
				fingerglyph.userInteractionEnabled = YES;
				fingerglyph.delegate = nil;
				lockView = nil;
			}
			%orig;
		});
	
	} else {
		if (self.bioAuthenticatedWhileMenuButtonDown) {
			return;
		}
		
		%orig;
		
		if (!self.isUILocked) {
			if (!useTickAnimation && useUnlockSound && unlockSound && shouldNotDelay) {
				AudioServicesPlaySystemSound(unlockSound);
			}
			fingerglyph = nil;
		}
	}
}

- (void)_finishUIUnlockFromSource:(int)source withOptions:(id)options {
	HBLogDebug(@"SBLockScreenManager::_finishUIUnlockFromSource:withOptions:");
	if (fingerglyph) {
		fingerglyph.delegate = nil;
		usingGlyph = NO;
		lockView = nil;
	}
	%orig;
}

- (void)biometricEventMonitor:(id)arg1 handleBiometricEvent:(unsigned long long)event {
	HBLogDebug(@"SBLockScreenManager::biometricEventMonitor:handleBiometricEvent: (%llu)", event);
	%orig;
	//start animation
	if (lockView && self.isUILocked && enabled && !authenticated) {
		switch (event) {
			case kTouchIDFingerDown:
				performFingerScanAnimation();
				break;
			case kTouchIDFingerUp:
				resetFingerScanAnimation();
				break;
		}
	}
}

%end

//------------------------------------------------------------------------------

%hook SBBiometricEventLogger

- (void)_tryAgain:(id)arg1 {
	HBLogDebug(@"SBBiometricEventLogger::_tryAgain:");
	%orig;
	SBLockScreenManager *manager = [%c(SBLockScreenManager) sharedInstance];
	if (lockView && manager.isUILocked && enabled && !authenticated) {
		if (shakeOnIncorrectFinger) {
			performShakeFingerFailAnimation();
		}
		if (vibrateOnIncorrectFinger) {
			AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
		}
	}
}

%end

//------------------------------------------------------------------------------

%hook SBLockScreenViewController

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
	HBLogDebug(@"rotated, updating glyph position");
	
	%orig;
	CGRect screen = [[UIScreen mainScreen] bounds];
	if (UIInterfaceOrientationIsLandscape(toInterfaceOrientation)) {
		if (landscapeY == 0 || !enableLandscapeY)
			fingerglyph.center = CGPointMake(screen.size.width+CGRectGetMidX(screen),screen.size.height-60);
		else
			fingerglyph.center = CGPointMake(screen.size.height+CGRectGetMidY(screen),landscapeY);
	} else {
		if (portraitY == 0 || !enablePortraitY)
			fingerglyph.center = CGPointMake(screen.size.width+CGRectGetMidX(screen),screen.size.height-60);
		else
			fingerglyph.center = CGPointMake(screen.size.width+CGRectGetMidX(screen),portraitY);
	}
}

%new
+ (PKGlyphView *)getLockGlyphView {
	return fingerglyph;
}

%end

//------------------------------------------------------------------------------

%hook SBLockScreenPasscodeOverlayViewController
- (void)viewWillAppear:(BOOL)arg1 {
	%orig;
	fingerglyph.hidden = YES;
}
- (void)_passcodeLockViewPasscodeEntered:(id)arg1 viaMesa:(BOOL)arg2 {
	%orig;
	fingerglyph.hidden = NO;
}
- (void)passcodeLockViewPasscodeEnteredViaMesa:(id)arg1 {
	%orig;
	fingerglyph.hidden = NO;
}
- (void)passcodeLockViewPasscodeEntered:(id)arg1 {
	%orig;
	fingerglyph.hidden = NO;
}
%end

//------------------------------------------------------------------------------

%hook SBAssistantController
- (void)_viewWillDisappearOnMainScreen:(BOOL)arg1 {
	HBLogDebug(@"SBAssistantController::_viewWillDisappearOnMainScreen:");
	if (fingerglyph) {
		resetFingerScanAnimation();
	}
	%orig;
}
%end

//------------------------------------------------------------------------------

%ctor {
	@autoreleasepool {
		HBLogDebug(@"Init");
		
		loadPreferences();
		
		CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(),
			NULL,
			(CFNotificationCallback)loadPreferences,
			CFSTR("com.evilgoldfish.lockglyphx.settingschanged"),
			NULL,
			CFNotificationSuspensionBehaviorDeliverImmediately
		);
	}
}

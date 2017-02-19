//
//  LockGlyphX.xm
//  LockGlyphX
//
//  evilgoldfish feat. sticktron 2017
//

#define DEBUG_PREFIX @"[LockGlyphX]"
#import "DebugLog.h"

#import "Headers.h"
#import "SpacemanBlocks.h"
#import "version.h"
#import <AudioToolbox/AudioServices.h>


#define kGlyphStateDefault 	0
#define kGlyphStateScanning 1
#define kGlyphStateCustom 	(IS_IOS_OR_NEWER(iOS_10_2) ? 6 : 5)
#define kGlyphStateTicked 	(IS_IOS_OR_NEWER(iOS_10_2) ? 7 : 6)

#define kTouchIDFingerUp 	0
#define kTouchIDFingerDown 	1
#define kTouchIDFingerHeld 	2
#define kTouchIDMatched 	3
#define kTouchIDSuccess 	4
#define kTouchIDNotMatched 	10

#define kPrefsAppID 					CFSTR("com.evilgoldfish.lockglyphx")
#define kSettingsChangedNotification 	CFSTR("com.evilgoldfish.lockglyphx.settingschanged")

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

// static NSString *CFRevert = @"ColorFlowLockScreenColorReversionNotification";
// static NSString *CFColor = @"ColorFlowLockScreenColorizationNotification";
// static NSString *CCRevert = @"CustomCoverLockScreenColourResetNotification";
// static NSString *CCColor = @"CustomCoverLockScreenColourUpdateNotification";


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
	
	NSDictionary *settings = nil;
	CFArrayRef keyList = CFPreferencesCopyKeyList(kPrefsAppID, kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
	if (keyList) {
		settings = (NSDictionary *)CFBridgingRelease(CFPreferencesCopyMultiple(keyList, kPrefsAppID, kCFPreferencesCurrentUser, kCFPreferencesAnyHost));
		DebugLogC(@"Got user preferences: %@", settings);
		CFRelease(keyList);
	} else {
		DebugLogC(@"No keylist from Prefs, no settings yet or error.");
	}
	
	enabled = 					settings[@"enabled"] ? [settings[@"enabled"] boolValue] : YES;
	useUnlockSound = 			settings[@"useUnlockSound"] ? [settings[@"useUnlockSound"] boolValue] : YES;
	useTickAnimation = 			settings[@"useTickAnimation"] ? [settings[@"useTickAnimation"] boolValue] : YES;
	useFasterAnimations = 		settings[@"useFasterAnimations"] ? [settings[@"useFasterAnimations"] boolValue] : NO;
	vibrateOnIncorrectFinger = 	settings[@"vibrateOnIncorrectFinger"] ? [settings[@"vibrateOnIncorrectFinger"] boolValue] : YES;
	shakeOnIncorrectFinger = 	settings[@"shakeOnIncorrectFinger"] ? [settings[@"shakeOnIncorrectFinger"] boolValue] : YES;
	useShine = 					settings[@"useShine"] ? [settings[@"useShine"] boolValue] : YES;
	primaryColor = 				settings[@"primaryColor"] ? parseColorFromPreferences(settings[@"primaryColor"]) : kDefaultPrimaryColor;
	secondaryColor = 			settings[@"secondaryColor"] ? parseColorFromPreferences(settings[@"secondaryColor"]) : kDefaultSecondaryColor;
	enablePortraitY = 			settings[@"enablePortraitY"] ? [settings[@"enablePortraitY"] boolValue] : NO;
	portraitY = 				settings[@"portraitY"] ? [settings[@"portraitY"] floatValue] : 0;
	enableLandscapeY = 			settings[@"enableLandscapeY"] ? [settings[@"enableLandscapeY"] boolValue] : NO;
	landscapeY = 				settings[@"landscapeY"] ? [settings[@"landscapeY"] floatValue] : 0;
	themeBundleName = 			settings[@"currentTheme"] ? settings[@"currentTheme"] : @"LockGlyph-Default.bundle";
	shouldNotDelay = 			settings[@"shouldNotDelay"] ? [settings[@"shouldNotDelay"] boolValue] : NO;
	
	// theme bundle
	NSURL *bundleURL = [NSURL fileURLWithPath:kBundlePath];
	themeAssets = [NSBundle bundleWithURL:[bundleURL URLByAppendingPathComponent:themeBundleName]];
	DebugLogC(@"found assets for theme (%@): %@", themeBundleName, themeAssets);
	
	// sound
	if (unlockSound) {
		AudioServicesDisposeSystemSoundID(unlockSound);
	}
	if ([[NSFileManager defaultManager] fileExistsAtPath:[themeAssets pathForResource:@"SuccessSound" ofType:@"wav"]]) {
		NSURL *pathURL = [NSURL fileURLWithPath:[themeAssets pathForResource:@"SuccessSound" ofType:@"wav"]];
		AudioServicesCreateSystemSoundID((__bridge CFURLRef)pathURL, &unlockSound);
	} else {
		DebugLogC(@"no sound for theme, using default instead");
		NSURL *pathURL = [NSURL fileURLWithPath:@"/Library/Application Support/LockGlyph/Themes/LockGlyph-Default.bundle/SuccessSound.wav"];
		AudioServicesCreateSystemSoundID((__bridge CFURLRef)pathURL, &unlockSound);
	}
}

static void performFingerScanAnimation(void) {
	DebugLogC(@"performFingerScanAnimation()");
	
	if (fingerglyph && [fingerglyph respondsToSelector:@selector(setState:animated:completionHandler:)]) {
		doingScanAnimation = YES;
		[fingerglyph setState:kGlyphStateScanning animated:YES completionHandler:^{
			doingScanAnimation = NO;
		}];
	}
}

static void resetFingerScanAnimation(void) {
	DebugLogC(@"resetFingerScanAnimation()");
	
	if (fingerglyph && [fingerglyph respondsToSelector:@selector(setState:animated:completionHandler:)]){
		if (fingerglyph.customImage)
			[fingerglyph setState:kGlyphStateCustom animated:YES completionHandler:nil];
		else
			[fingerglyph setState:kGlyphStateDefault animated:YES completionHandler:nil];
	}
}

static void performTickAnimation(void) {
	DebugLogC(@"performTickAnimation()");
	
	if (fingerglyph && [fingerglyph respondsToSelector:@selector(setState:animated:completionHandler:)]) {
		doingTickAnimation = YES;
		[fingerglyph setState:kGlyphStateTicked animated:YES completionHandler:^{
			doingTickAnimation = NO;
		}];
	}
	DebugLogC(@"can't find fingerglyph :(");
}

static void performShakeFingerFailAnimation(void) {
	DebugLogC(@"performShakeFingerFailAnimation()");
	
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


@interface PKGlyphView (LockGlyphX)
- (void)updatePositionWithOrientation:(UIInterfaceOrientation)orientation;
@end

@interface SBDashBoardPageViewBase (LockGlyphX)
- (void)addShineAnimationToView:(UIView *)aView;
@end

@interface SBDashBoardMesaUnlockBehavior (LockGlyphX)
- (void)handleBiometricEventCommon:(unsigned long long)event;
@end


// TESTS -----------------------------------------------------------------------


// Custom Unlock Text
// %hook SBUICallToActionLabel
// - (void)setText:(id)arg1 forLanguage:(id)arg2 animated:(BOOL)arg3 {
// 	%orig(@"LockGlyphX", arg2, arg3);
// }
// %end


// Delay Unlock
// %hook SBBacklightController
// - (double)defaultLockScreenDimInterval {
// 	double r = %orig;
// 	DebugLog(@"defaultLockScreenDimInterval = %f", r);
// 	return 60.0;
// }
// - (double)defaultLockScreenDimIntervalWhenNotificationsPresent {
// 	double r = %orig;
// 	DebugLog(@"defaultLockScreenDimIntervalWhenNotificationsPresent = %f", r);
// 	return 60.0;
// }
// %end


// END TESTS -------------------------------------------------------------------


%hook SBDashBoardPageViewBase

- (void)didMoveToWindow {
	%orig;
	
	// There is more than one page based on this class, we are only interested
	// in the "main" page.
	if (![self.pageViewController isKindOfClass:[%c(SBDashBoardMainPageViewController) class]]) {
		return;
	}
	
	// main page is leaving it's window, do some clean up
	if (!self.window) {
		DebugLog(@"main page has left window");
		
		// stop notifications from ColorFlow/CustomCover
		// [[NSNotificationCenter defaultCenter] removeObserver:self];
		// // [[NSNotificationCenter defaultCenter] removeObserver:self name:CFRevert object:nil];
		// // [[NSNotificationCenter defaultCenter] removeObserver:self name:CFColor object:nil];
		// // [[NSNotificationCenter defaultCenter] removeObserver:self name:CCRevert object:nil];
		// // [[NSNotificationCenter defaultCenter] removeObserver:self name:CCColor object:nil];
		
		// revert CustomCover override
		if (overrideIsForCustomCover) {
			setPrimaryColorOverride(nil);
			setSecondaryColorOverride(nil);
		}
		
		return;
	}
	
	DebugLog(@"Main LockScreen page has moved to window !!!");
	
	DebugLog(@"fingerglyph? %@", fingerglyph);
	if (fingerglyph) {
		DebugLog(@"******** found old fingerglyph, shouldn't be here, kill with fire...");
		// ?
	}
	
	if (enabled) {
		// listen for notifications from ColorFlow/CustomCover
		// [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(LG_RevertUI:) name:CFRevert object:nil];
		// [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(LG_ColorizeUI:) name:CFColor object:nil];
		// [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(LG_RevertUI:) name:CCRevert object:nil];
		// [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(LG_ColorizeUI:) name:CCColor object:nil];
		
		lockView = (UIView *)self;
		authenticated = NO;
		usingGlyph = YES;
		
		DebugLog(@"creating new GlyphView to your specifications...");
		fingerglyph = [[%c(PKGlyphView) alloc] initWithStyle:0]; // 1 = blended
		fingerglyph.delegate = (id<PKGlyphViewDelegate>)self;
		fingerglyph.primaryColor = activePrimaryColor();
		fingerglyph.secondaryColor = activeSecondaryColor();
		
		// NEW FEATURE? 'BLEND MODE' -------------------------------------------
		// [fingerglyph _setDrawsAsBackdropOverlayWithBlendMode:kCGBlendModePlusDarker];
		// fingerglyph.tintColor = [UIColor colorWithWhite:0 alpha:0.50];
		
		// load theme image
		if (themeAssets && ([[NSFileManager defaultManager] fileExistsAtPath:[themeAssets pathForResource:@"IdleImage" ofType:@"png"]] || [[NSFileManager defaultManager] fileExistsAtPath:[themeAssets pathForResource:@"IdleImage@2x" ofType:@"png"]])) {
			DebugLog(@"found active theme: %@", themeAssets);
			UIImage *customImage = [UIImage imageWithContentsOfFile:[themeAssets pathForResource:@"IdleImage" ofType:@"png"]];
			DebugLog(@"using custom image: %@", customImage);
			
			// fix scale?
			UIImage *customImageWithScale = [UIImage imageWithCGImage:customImage.CGImage scale:[UIScreen mainScreen].scale orientation:customImage.imageOrientation];
			
			[fingerglyph setCustomImage:customImageWithScale.CGImage withAlignmentEdgeInsets:UIEdgeInsetsZero];
			//[fingerglyph setCustomImage:customImageWithScale.CGImage withAlignmentEdgeInsets:UIEdgeInsetsMake(-50,-50,-50,-50)];
			
			// set glyph to custom mode
			[fingerglyph setState:kGlyphStateCustom animated:NO completionHandler:nil];
			
			// fix size?
			// CGRect frame = fingerglyph.frame;
			// frame.size = CGSizeMake(200,200);
			// fingerglyph.frame = frame;
			
		// } else {
		// 	[fingerglyph setCustomImage:nil withAlignmentEdgeInsets:UIEdgeInsetsZero];
		}
		
		// position glyph
		[fingerglyph updatePositionWithOrientation:[[UIApplication sharedApplication] statusBarOrientation]];
		DebugLog(@"fingerglyph.frame = %@", NSStringFromCGRect(fingerglyph.frame));
		
		// add shine animation
		if (useShine) {
			[self addShineAnimationToView:fingerglyph];
		}
		
		// add tap recognizer
		UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(lockGlyphTapHandler:)];
		[fingerglyph addGestureRecognizer:tap];
		
		[self addSubview:fingerglyph];
	}
}

%new
- (void)addShineAnimationToView:(UIView*)aView {
	/*
	 * Taken from this StackOverflow answer: http://stackoverflow.com/a/26081621
	 */
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
	DebugLog(@"glyph was tapped");
	
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

%new
- (void)glyphView:(PKGlyphView *)arg1 revealingCheckmark:(BOOL)arg2 {
	DebugLog(@"revealingCheckmark:%@", arg2?@"YES":@"NO");
	if (useUnlockSound && useTickAnimation && unlockSound) {
		AudioServicesPlaySystemSound(unlockSound);
	}
}

- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	%orig;
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

%end


//------------------------------------------------------------------------------


%hook PKGlyphView
%new
- (void)updatePositionWithOrientation:(UIInterfaceOrientation)orientation {
	DebugLog(@"updating glyph position for orientation: %ld", (long)orientation);
	
	CGRect screen = [[UIScreen mainScreen] bounds];
	if (UIInterfaceOrientationIsLandscape(orientation)) {
		DebugLog(@"in landscape orientation");
		if (landscapeY == 0 || !enableLandscapeY) {
			fingerglyph.center = CGPointMake(CGRectGetMidX(screen), screen.size.height - kDefaultYOffset);
		} else {
			fingerglyph.center = CGPointMake(CGRectGetMidY(screen), landscapeY);
		}
	} else {
		DebugLog(@"in portrait orientation");
		if (portraitY == 0 || !enablePortraitY) {
			fingerglyph.center = CGPointMake(CGRectGetMidX(screen), screen.size.height - kDefaultYOffset);
		} else {
			fingerglyph.center = CGPointMake(CGRectGetMidX(screen), portraitY);
		}
	}
}
%end


//------------------------------------------------------------------------------


%hook PKSubglyphView

- (void)_setProgress:(double)arg1 withDuration:(double)arg2 forShapeLayerAtIndex:(unsigned long long)arg {
	DebugLog0;
	
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

- (double)_minimumAnimationDurationForStateTransition {
	DebugLog0;
	
	return authenticated && useFasterAnimations && usingGlyph && (doingTickAnimation || doingScanAnimation) ? 0.1 : %orig;
}

// test
- (void)subglyphView:(PKSubglyphView *)arg1 didLayoutContentLayer:(CALayer *)arg2 {
	DebugLog0;
	%orig;
}

%end


//------------------------------------------------------------------------------


// %hook SBLockScreenManager
// - (void)_finishUIUnlockFromSource:(int)source withOptions:(id)options {
// 	DebugLog0;
//
// 	// destroy the GlyphView and reset state
// 	if (fingerglyph) {
// 		DebugLog(@"destroying fingerglyph");
// 		[fingerglyph removeFromSuperview];
// 		fingerglyph.delegate = nil;
// 		fingerglyph = nil;
//
// 		usingGlyph = NO;
// 		lockView = nil;
// 	}
// 	%orig;
// }
// %end


//------------------------------------------------------------------------------


%hook SBDashBoardViewController

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)orientation duration:(NSTimeInterval)duration {
	DebugLog0;
	%orig;
	[fingerglyph updatePositionWithOrientation:orientation];
}
- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)orientation duration:(NSTimeInterval)duration {
	DebugLog0;
	%orig;
	
	[UIView animateWithDuration:duration
						  delay:0
						options:UIViewAnimationOptionCurveLinear
					 animations:^(void) { [fingerglyph updatePositionWithOrientation:orientation]; }
					 completion:nil];
}

- (BOOL)mesaUnlockBehavior:(id)arg1 requestsUnlock:(id)arg2 withFeedback:(id)arg3 {
	// DebugLog(@"behavior: %@", arg1);
	// DebugLog(@"requestsUnlock: %@", arg2);
	// DebugLog(@"withFeedback: %@", arg3);
	DebugLog(@"TouchID wants to unlock");
	
	if (!enabled) {
		return %orig;
	}
	
	SBLockScreenManager *manager = [%c(SBLockScreenManager) sharedInstance];
	
	// if ([%c(SBAssistantController) isAssistantVisible] || manager.bioAuthenticatedWhileMenuButtonDown) {
	// 	DebugLog(@"isAssistantVisible || bioAuthenticatedWhileMenuButtonDown");
	// 	if (unlockBlock) {
	// 		cancel_delayed_block(unlockBlock);
	// 	}
	// 	return;
	// }
	
	// if (lockView && manager.isUILocked && enabled && !authenticated && !shouldNotDelay && ![manager.lockScreenViewController isPasscodeLockVisible]) {
	if (!authenticated && !shouldNotDelay && ![manager.lockScreenViewController isPasscodeLockVisible]) {
		DebugLog(@"!authenticated && !shouldNotDelay && !passcodeVisible");
	
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
		
		// wait somehow while blocking UI
		sleep(delayInSeconds);
		
		return %orig;
		
		// dispatch_after(dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC), dispatch_get_main_queue(), ^(void){
		// 	DebugLog(@"performing block after delay now");
		// 	if (!useTickAnimation && useUnlockSound && unlockSound) {
		// 		AudioServicesPlaySystemSound(unlockSound);
		// 	}
		// 	%orig;
		// });
		
		// unlockBlock = perform_block_after_delay(delayInSeconds, ^(void){
		// 	DebugLog(@"performing block after delay now");
		// 	if (!useTickAnimation && useUnlockSound && unlockSound) {
		// 		AudioServicesPlaySystemSound(unlockSound);
		// 	}
		// 	if (fingerglyph) {
		// 		fingerglyph.userInteractionEnabled = YES;
		// 	// 	fingerglyph.delegate = nil;
		// 	// 	lockView = nil;
		// 	}
		// 	return %orig;
		// });
	
	} else {
		if (manager.bioAuthenticatedWhileMenuButtonDown) {
			DebugLog(@"bioAuthenticatedWhileMenuButtonDown");
		// 	return;
		}
	
		if (!manager.isUILocked) {
			DebugLog(@"!manager.isUILocked");
			if (!useTickAnimation && useUnlockSound && unlockSound && shouldNotDelay) {
				DebugLog(@"!useTickAnimation && useUnlockSound && unlockSound && shouldNotDelay");
				AudioServicesPlaySystemSound(unlockSound);
			}
			// fingerglyph = nil;
		}
	
		return %orig;
	}
}

%end

//------------------------------------------------------------------------------

%hook SBDashBoardMesaUnlockBehavior

// iOS < 10.2 ??
// - (void)biometricEventMonitor:(id)arg1 handleBiometricEvent:(unsigned long long)event {
// 	DebugLog0;
// 	%orig;
// }

// iOS 10.2
- (void)handleBiometricEvent:(unsigned long long)event {
	if (!enabled) {
		%orig;
		return;
	}
	DebugLog(@"Biometric event occured: %llu", event);
	
	SBLockScreenManager *manager = [%c(SBLockScreenManager) sharedInstance];
	
	switch (event) {
		
		case kTouchIDFingerDown:
			DebugLog(@"TouchID: finger down");
			if (lockView && [manager isUILocked] && enabled && !authenticated) {
				performFingerScanAnimation();
			}
			%orig;
			break;
			
		case kTouchIDFingerUp:
			DebugLog(@"TouchID: finger up");
			if (lockView && [manager isUILocked] && enabled && !authenticated) {
				resetFingerScanAnimation();
			}
			%orig;
			break;
			
		case kTouchIDNotMatched:
			DebugLog(@"TouchID: match failed");
			if (shakeOnIncorrectFinger) {
				performShakeFingerFailAnimation();
			}
			if (vibrateOnIncorrectFinger) {
				AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
			}
			%orig;
			break;
			
		// case kTouchIDSuccess:
/*
		case kTouchIDMatched:
			DebugLog(@"TouchID wants to unlock");
			
			if ([%c(SBAssistantController) isAssistantVisible] || manager.bioAuthenticatedWhileMenuButtonDown) {
				DebugLog(@"isAssistantVisible || bioAuthenticatedWhileMenuButtonDown");
				if (unlockBlock) {
					cancel_delayed_block(unlockBlock);
				}
				%orig;
				return;
			}
			
			// if (lockView && manager.isUILocked && enabled && !authenticated && !shouldNotDelay && ![manager.lockScreenViewController isPasscodeLockVisible]) {
			if (!authenticated && !shouldNotDelay && ![manager.lockScreenViewController isPasscodeLockVisible]) {
				DebugLog(@"!authenticated && !shouldNotDelay && !passcodeVisible");
				
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
				
				DebugLog(@"sleeping...");
				sleep(delayInSeconds);
				%orig;
				
				// dispatch_after(dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC), dispatch_get_main_queue(), ^(void){
				// 	DebugLog(@"performing block after delay now");
				// 	if (!useTickAnimation && useUnlockSound && unlockSound) {
				// 		AudioServicesPlaySystemSound(unlockSound);
				// 	}
				// 	%orig;
				// });
				
				// unlockBlock = perform_block_after_delay(delayInSeconds, ^(void){
				// 	DebugLog(@"performing block after delay now");
				// 	if (!useTickAnimation && useUnlockSound && unlockSound) {
				// 		AudioServicesPlaySystemSound(unlockSound);
				// 	}
				// 	// if (fingerglyph) {
				// 	// 	fingerglyph.userInteractionEnabled = YES;
				// 	// 	fingerglyph.delegate = nil;
				// 	// 	lockView = nil;
				// 	// }
				// 	%orig;
				// });
			
			} else {
				if (manager.bioAuthenticatedWhileMenuButtonDown) {
					DebugLog(@"bioAuthenticatedWhileMenuButtonDown");
					%orig;
					return;
				}
				
				if (!manager.isUILocked) {
					if (!useTickAnimation && useUnlockSound && unlockSound && shouldNotDelay) {
						AudioServicesPlaySystemSound(unlockSound);
					}
					// fingerglyph = nil;
				}
				
				%orig;
			}
*/
		
		default:
			%orig;
			break;
	}
}

%end

//------------------------------------------------------------------------------

%hook SBLockScreenViewController
- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
	DebugLog0;
	
	%orig;
	
	[UIView animateWithDuration:duration
						  delay:0
						options:UIViewAnimationOptionCurveLinear
					 animations:^(void) { [fingerglyph updatePositionWithOrientation:toInterfaceOrientation]; }
					 completion:nil];
}
%end

//------------------------------------------------------------------------------

%hook SBAssistantController
- (void)_viewWillDisappearOnMainScreen:(BOOL)arg1 {
	DebugLog0;
	if (fingerglyph) {
		resetFingerScanAnimation();
	}
	%orig;
}
- (void)_viewDidDisappearOnMainScreen:(BOOL)arg1 {
	DebugLog0;
	if (fingerglyph) {
		resetFingerScanAnimation();
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

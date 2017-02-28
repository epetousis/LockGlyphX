//
//  Headers.h
//  LockGlyphX
//

// Private APIs

#import "Headers/PKGlyphView.h"

@protocol SBDashBoardPageViewControllerProtocol;

@interface SBBiometricEventLogger : NSObject
@end

@interface PKSubglyphView : UIView
@end

@interface PKFingerprintGlyphView : UIView
@property (nonatomic,readonly) UIView * contentView;
@end

@interface SBLockScreenViewControllerBase : UIViewController
- (BOOL)isPasscodeLockVisible;
@end

@interface SBLockScreenViewController : SBLockScreenViewControllerBase
@end

@interface SBLockScreenManager : NSObject
+ (id)sharedInstance;
- (void)unlockUIFromSource:(int)arg1 withOptions:(id)arg2;
- (void)_finishUIUnlockFromSource:(int)arg1 withOptions:(id)arg2;
// - (void)_bioAuthenticated:(id)arg1;
// - (void)_lockUI;
// - (BOOL)attemptUnlockWithPasscode:(id)passcode;
// @property(nonatomic, getter=isUIUnlocking) BOOL UIUnlocking;
// @property(readonly) BOOL isWaitingToLockUI;
@property(readonly) BOOL isUILocked;
@property(readonly, nonatomic) SBLockScreenViewController *lockScreenViewController;
@property(readonly) BOOL bioAuthenticatedWhileMenuButtonDown;
@end

@interface SBAssistantController : NSObject
+ (BOOL)isAssistantVisible;
@end

@interface SBDashBoardViewBase : UIView
@end

@interface SBDashBoardMainPageView : SBDashBoardViewBase
@end

@interface SBDashBoardPageViewBase : SBDashBoardViewBase
@property(nonatomic) __weak UIViewController<SBDashBoardPageViewControllerProtocol> *pageViewController; // @synthesize pageViewController=_pageViewController;
@end

@interface SBDashBoardTodayPageView : SBDashBoardPageViewBase
@end

@interface SBDashBoardMainPageViewController : UIViewController
@end

@interface SBDashBoardMainPageContentViewController : UIViewController
@end

@interface UIView (Private)
- (void)_setDrawsAsBackdropOverlayWithBlendMode:(long long)arg1;
- (void)_setDrawsAsBackdropOverlay:(_Bool)arg1;
@end

@interface SBDashBoardViewController : UIViewController
@end

@interface SBDashBoardMesaUnlockBehavior : NSObject
- (void)_handleMesaFailure;
- (void)biometricEventMonitor:(id)arg1 handleBiometricEvent:(unsigned long long)arg2;
@end

@interface SBUICallToActionLabel : UIView
- (void)setText:(NSString *)arg1;
@end

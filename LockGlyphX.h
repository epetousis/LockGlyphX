@interface SBLockScreenView
- (void)setSlideToUnlockHidden:(BOOL)arg1 forRequester:(id)arg2;
@end

@interface SBLockScreenViewControllerBase : UIViewController
- (BOOL)isPasscodeLockVisible;
@end

@interface SBLockScreenViewController : SBLockScreenViewControllerBase
- (SBLockScreenView *)lockScreenView;
@end

@interface SBLockScreenManager : NSObject
+ (id)sharedInstance;
- (void)unlockUIFromSource:(int)arg1 withOptions:(id)arg2;
- (void)_finishUIUnlockFromSource:(int)arg1 withOptions:(id)arg2;
- (void)_bioAuthenticated:(id)arg1;
- (void)_lockUI;
- (BOOL)attemptUnlockWithPasscode:(id)passcode;
@property(nonatomic, getter=isUIUnlocking) BOOL UIUnlocking;
@property(readonly) BOOL isWaitingToLockUI;
@property(readonly) BOOL isUILocked;
@property(readonly, nonatomic) SBLockScreenViewController *lockScreenViewController;
@property(readonly) BOOL bioAuthenticatedWhileMenuButtonDown;
@end

@interface SBAssistantController : NSObject
+ (BOOL)isAssistantVisible;
@end

@interface SBDashBoardMainPageView : UIView
@end

@interface UIView (Private)
- (void)_setDrawsAsBackdropOverlayWithBlendMode:(long long)arg1;
- (void)_setDrawsAsBackdropOverlay:(_Bool)arg1;
@end

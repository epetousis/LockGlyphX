/* Generated by RuntimeBrowser
   Image: /System/Library/PrivateFrameworks/PassKitUIFoundation.framework/PassKitUIFoundation
 */

#import "PKGlyphViewDelegate.h"
#import "PKSubglyphViewDelegate.h"

@interface PKGlyphView : UIView <PKSubglyphViewDelegate> {
//     PKCheckGlyphLayer * _checkLayer;
//     struct CGImage { } * _customImage;
//     struct UIEdgeInsets {
//         float top;
//         float left;
//         float bottom;
//         float right;
//     }  _customImageAlignmentEdgeInsets;
//     CALayer * _customImageLayer;
//     <PKGlyphViewDelegate> * _delegate;
//     double  _lastAnimationWillFinish;
//     struct {
//         unsigned int showingPhone : 1;
//         unsigned int phoneRotated : 1;
//     }  _layoutFlags;
//     float  _phoneAspectRatio;
//     PKPhoneGlyphLayer * _phoneLayer;
//     NSString * _phoneWiggleAnimationKey;
//     BOOL  _phoneWiggling;
//     UIColor * _primaryColor;
//     int  _priorState;
//     UIColor * _secondaryColor;
//     int  _state;
//     int  _style;
//     PKSubglyphView * _subglyphView;
//     NSMutableArray * _transitionCompletionHandlers;
//     unsigned int  _transitionIndex;
//     BOOL  _transitioning;
}

@property (nonatomic, readonly) CGImage *customImage;
@property (nonatomic, readonly) UIEdgeInsets customImageAlignmentEdgeInsets;
@property (readonly, copy) NSString *debugDescription;
@property (nonatomic) id <PKGlyphViewDelegate> delegate;
@property (readonly, copy) NSString *description;
@property (nonatomic) BOOL fadeOnRecognized;
// @property (readonly) unsigned int hash;
@property (nonatomic, copy) UIColor *primaryColor;
@property (nonatomic, copy) UIColor *secondaryColor;
@property (nonatomic, readonly) int state;
@property (readonly) Class superclass;

+ (BOOL)automaticallyNotifiesObserversOfState;

- (UIColor *)_defaultPrimaryColor;
- (UIColor *)_defaultSecondaryColor;
- (void)_endPhoneWiggle;
- (void)_executeAfterMinimumAnimationDurationForStateTransition:(id /* block */)arg1;
- (void)_executeTransitionCompletionHandlers:(BOOL)arg1;
- (void)_finishTransitionForIndex:(unsigned int)arg1;
- (void)_layoutContentLayer:(id)arg1;
- (double)_minimumAnimationDurationForStateTransition;
- (void)_performTransitionWithTransitionIndex:(unsigned int)arg1 animated:(BOOL)arg2;
- (CGPoint)_phonePositionDeltaWhileShownFromRotationPercentage:(float)arg1 toPercentage:(float)arg2;
- (CGPoint)_phonePositionWhileShownWithRotationPercentage:(float)arg1;
- (CATransform3D)_phoneTransformDeltaWhileShownFromRotationPercentage:(float)arg1 toPercentage:(float)arg2;
- (void)_startPhoneWiggle;
- (void)_updateCheckViewStateAnimated:(BOOL)arg1;
- (void)_updateCustomImageLayerOpacityAnimated:(BOOL)arg1;
- (void)_updateLastAnimationTimeWithAnimationOfDuration:(double)arg1;
- (void)_updatePhoneLayoutWithTransitionIndex:(unsigned int)arg1 animated:(BOOL)arg2;
- (void)_updatePhoneWiggleIfNecessary;
- (id)createCustomImageLayer;
- (CGImage *)customImage;
- (UIEdgeInsets)customImageAlignmentEdgeInsets;
- (void)dealloc;
- (id)delegate;
- (BOOL)fadeOnRecognized;
- (id)initWithCoder:(id)arg1;
- (id)initWithFrame:(CGRect)arg1;
// - (id)initWithStyle:(int)arg1;
- (void)layoutSubviews;
- (id)primaryColor;
- (id)secondaryColor;
- (void)setCustomImage:(CGImage *)arg1 withAlignmentEdgeInsets:(UIEdgeInsets)arg2;
- (void)setDelegate:(id <PKGlyphViewDelegate>)arg1;
- (void)setFadeOnRecognized:(BOOL)arg1;
- (void)setPrimaryColor:(UIColor *)arg1;
- (void)setPrimaryColor:(UIColor *)arg1 animated:(BOOL)arg2;
- (void)setSecondaryColor:(UIColor *)arg1;
- (void)setSecondaryColor:(UIColor *)arg1 animated:(BOOL)arg2;
- (void)setState:(int)arg1;
- (void)setState:(int)arg1 animated:(BOOL)arg2 completionHandler:(id /* block */)arg3;
- (int)state;
- (void)subglyphView:(id)arg1 didLayoutContentLayer:(id)arg2;
- (void)updateRasterizationScale:(float)arg1;

@end

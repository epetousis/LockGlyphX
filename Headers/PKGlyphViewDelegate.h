@class PKGlyphView;

@protocol PKGlyphViewDelegate <NSObject>

@optional
- (void)glyphView:(PKGlyphView *)arg1 revealingCheckmark:(BOOL)arg2;
- (void)glyphView:(PKGlyphView *)arg1 transitioningToState:(int)arg2;
@end

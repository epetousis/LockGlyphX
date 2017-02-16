@class PKSubglyphView;

@protocol PKSubglyphViewDelegate <NSObject>

@required
- (void)subglyphView:(PKSubglyphView *)arg1 didLayoutContentLayer:(CALayer *)arg2;
@end

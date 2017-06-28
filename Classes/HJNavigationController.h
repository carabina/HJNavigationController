/**
 * 👨‍💻 Haijun
 * 📅 2017-06-26
 */

#import <UIKit/UIKit.h>

@interface HJNavigationController : UINavigationController

@end

@interface UIViewController (HJNavigation)

@property (nonatomic, assign) CGFloat hj_navigationBarAlpha;
@property (nonatomic, strong) UIColor *hj_navigaitonBarColor;

@end

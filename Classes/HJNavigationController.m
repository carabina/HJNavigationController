/**
 * 👨‍💻 Haijun
 * 📅 2017-06-26
 */

#import "HJNavigationController.h"
#import <objc/runtime.h>


#pragma mark -------------------- UINavigationBar --------------------

@interface UINavigationBar (HJNavigation)

- (void)hj_setBackgroundAlpha:(CGFloat)alpha;
- (void)hj_setBackgroundColor:(UIColor *)color;

@end

@implementation UINavigationBar (HJNavigation)

static char kHJBackgroundViewKey;

- (void)setHj_backgroundView:(UIView *)hj_backgroundView {
    objc_setAssociatedObject(self, &kHJBackgroundViewKey, hj_backgroundView, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (UIView *)hj_backgroundView {
    UIView *backgroundView = objc_getAssociatedObject(self, &kHJBackgroundViewKey);
    if (!backgroundView) {
        UIView *barBackgroundView = self.subviews.firstObject;
        if (![barBackgroundView isKindOfClass:NSClassFromString(@"_UIBarBackground")]) { return nil; }
        backgroundView = [[UIView alloc] initWithFrame:barBackgroundView.bounds];
        backgroundView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        
        [self setShadowImage:[UIImage new]];
        [self setBackgroundImage:[UIImage new] forBarMetrics:UIBarMetricsDefault];
        [barBackgroundView insertSubview:self.hj_backgroundView = backgroundView atIndex:0];
    }
    
    return backgroundView;
}

- (void)hj_setBackgroundAlpha:(CGFloat)alpha {
    UIView *barBackgroundView = self.subviews.firstObject;
    barBackgroundView.alpha = alpha;
}

- (void)hj_setBackgroundColor:(UIColor *)color {
    self.hj_backgroundView.backgroundColor = color;
}

@end


#pragma mark -------------------- HJNavigationController --------------------

@interface HJNavigationController () <UINavigationBarDelegate>

@property (nonatomic, assign) NSInteger displayCount;

@end

@interface UINavigationController (HJNavigation)

- (void)_updateInteractiveTransition:(CGFloat)percentComplete;

@end

@implementation HJNavigationController

#pragma mark - Class method

#pragma mark - Life cycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationBar.delegate = self;
    [self.navigationBar hj_backgroundView];
}

#pragma mark - Override

- (void)_updateInteractiveTransition:(CGFloat)percentComplete {
    [super _updateInteractiveTransition:percentComplete];
    
    UIViewController *toViewController = [self.topViewController.transitionCoordinator viewControllerForKey:UITransitionContextToViewControllerKey];
    UIViewController *fromViewController = [self.topViewController.transitionCoordinator viewControllerForKey:UITransitionContextFromViewControllerKey];
    [self updateNavigationBarWithFromViewController:fromViewController toViewController:toViewController percent:percentComplete];
}

- (NSArray<UIViewController *> *)popToViewController:(UIViewController *)viewController animated:(BOOL)animated {
    __block NSArray *resultVCs;
    [self navigationBarDisplayLinkWithTransactionBlock:^{
        resultVCs = [super popToViewController:viewController animated:animated];
    }];
    return resultVCs;
}

- (NSArray<UIViewController *> *)popToRootViewControllerAnimated:(BOOL)animated {
    __block NSArray *resultVCs;
    [self navigationBarDisplayLinkWithTransactionBlock:^{
        resultVCs = [super popToRootViewControllerAnimated:animated];
    }];
    return resultVCs;
}

- (void)pushViewController:(UIViewController *)viewController animated:(BOOL)animated {
    [self navigationBarDisplayLinkWithTransactionBlock:^{
        [super pushViewController:viewController animated:animated];
    }];
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return [self.topViewController preferredStatusBarStyle];
}

#pragma mark - Event response

/**
 导航栏刷新CADisplayLink事件响应
 */
- (void)navigationBarDisplayLinkAction {
    if (!self.topViewController || !self.topViewController.transitionCoordinator) { return; }
    self.displayCount += 1;
    CGFloat percent = MIN(1, self.displayCount / 13.0); /* push or pop动画计数平均值为13左右 */
    UIViewController *toViewController = [self.topViewController.transitionCoordinator viewControllerForKey:UITransitionContextToViewControllerKey];
    UIViewController *fromViewController = [self.topViewController.transitionCoordinator viewControllerForKey:UITransitionContextFromViewControllerKey];
    [self updateNavigationBarWithFromViewController:fromViewController toViewController:toViewController percent:percent];
}

#pragma mark - Protocol

#pragma mark <UINavigationBarDelegate>

- (BOOL)navigationBar:(UINavigationBar *)navigationBar shouldPopItem:(UINavigationItem *)item {
    __weak typeof (self) weakSelf = self;
    id<UIViewControllerTransitionCoordinator> coor = [self.topViewController transitionCoordinator];
    if ([coor initiallyInteractive]) {
        NSString *sysVersion = [[UIDevice currentDevice] systemVersion];
        if ([sysVersion floatValue] >= 10) {
            [coor notifyWhenInteractionChangesUsingBlock:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
                __strong typeof (self) strongSelf = weakSelf;
                [strongSelf dealInteractionChanges:context];
            }];
        } else {
            [coor notifyWhenInteractionEndsUsingBlock:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
                __strong typeof (self) strongSelf = weakSelf;
                [strongSelf dealInteractionChanges:context];
            }];
        }
        return YES;
    }
    
    NSUInteger itemCount = self.navigationBar.items.count;
    NSUInteger n = self.viewControllers.count >= itemCount ? 2 : 1;
    UIViewController *popToVC = self.viewControllers[self.viewControllers.count - n];
    [self popToViewController:popToVC animated:YES];
    return YES;
}

#pragma mark - Private method

- (UIColor *)gradientColorWithColor1:(UIColor *)color1 color2:(UIColor *)color2 percent:(CGFloat)percent{
    CGFloat r1, g1, b1, alpha1;
    [color1 getRed:&r1 green:&g1 blue:&b1 alpha:&alpha1];
    
    CGFloat r2, g2, b2, alpha2;
    [color2 getRed:&r2 green:&g2 blue:&b2 alpha:&alpha2];
    
    CGFloat newR = r1 + (r2 - r1) * percent;
    CGFloat newG = g1 + (g2 - g1) * percent;
    CGFloat newB = b1 + (b2 - b1) * percent;
    CGFloat newAlpha = alpha1 + (alpha2 - alpha1) * percent;
    
    return [UIColor colorWithRed:newR green:newG blue:newB alpha:newAlpha];
}

- (CGFloat)gradientAlphaWithFromAlpha:(CGFloat)fromAlpha toAlpha:(CGFloat)toAlpha percent:(CGFloat)percent {
    return fromAlpha + (toAlpha - fromAlpha) * percent;
}

- (void)updateNavigationBarWithFromViewController:(UIViewController *)fromViewController toViewController:(UIViewController *)toViewController percent:(CGFloat)percent {
    [self.navigationBar hj_setBackgroundAlpha:[self gradientAlphaWithFromAlpha:fromViewController.hj_navigationBarAlpha
                                                                           toAlpha:toViewController.hj_navigationBarAlpha
                                                                           percent:percent]];
    [self.navigationBar hj_setBackgroundColor:[self gradientColorWithColor1:fromViewController.hj_navigaitonBarColor
                                                                         color2:toViewController.hj_navigaitonBarColor
                                                                        percent:percent]];
}

- (void)dealInteractionChanges:(id<UIViewControllerTransitionCoordinatorContext>)context {
    void (^animations) (UITransitionContextViewControllerKey) = ^(UITransitionContextViewControllerKey key){
        CGFloat currentAlpha = [[context viewControllerForKey:key] hj_navigationBarAlpha];
        UIColor *currentColor = [[context viewControllerForKey:key] hj_navigaitonBarColor];
        
        [self.navigationBar hj_setBackgroundAlpha:currentAlpha];
        [self.navigationBar hj_setBackgroundColor:currentColor];
    };
    
    if ([context isCancelled]) {
        CGFloat cancelDuration = [context transitionDuration] * [context percentComplete];
        [UIView animateWithDuration:cancelDuration animations:^{
            animations(UITransitionContextFromViewControllerKey);
        }];
    } else {
        CGFloat finishDuration = [context transitionDuration] * (1 - [context percentComplete]);
        [UIView animateWithDuration:finishDuration animations:^{
            animations(UITransitionContextToViewControllerKey);
        }];
    }
}

- (void)navigationBarDisplayLinkWithTransactionBlock:(void(^)())transactionBlock {
    __block CADisplayLink *displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(navigationBarDisplayLinkAction)];
    [displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
    [CATransaction setCompletionBlock:^{
        [displayLink invalidate];
        self.displayCount = 0;
        [self.navigationBar hj_setBackgroundAlpha:self.topViewController.hj_navigationBarAlpha];
        [self.navigationBar hj_setBackgroundColor:self.topViewController.hj_navigaitonBarColor];
    }];
    
    [CATransaction begin];
    transactionBlock();
    [CATransaction commit];
}

@end



#pragma mark -------------------- UIViewController --------------------

@implementation UIViewController (HJNavigation)

static char kHJNavigationBarAlphaKey;
static char kHJNavigationBarColorKey;

- (void)setHj_navigationBarAlpha:(CGFloat)hj_navigationBarAlpha {
    [self.navigationController.navigationBar hj_setBackgroundAlpha:hj_navigationBarAlpha];
    objc_setAssociatedObject(self, &kHJNavigationBarAlphaKey, @(hj_navigationBarAlpha), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (CGFloat)hj_navigationBarAlpha {
    NSNumber *alpha = objc_getAssociatedObject(self, &kHJNavigationBarAlphaKey);
    return alpha ? [alpha floatValue] : 1;
}

- (void)setHj_navigaitonBarColor:(UIColor *)hj_navigaitonBarColor {
    self.navigationController.navigationBar.hj_backgroundView.backgroundColor = hj_navigaitonBarColor;
    objc_setAssociatedObject(self, &kHJNavigationBarColorKey, hj_navigaitonBarColor, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (UIColor *)hj_navigaitonBarColor {
    return objc_getAssociatedObject(self, &kHJNavigationBarColorKey) ? : [UIColor lightGrayColor];
}

@end

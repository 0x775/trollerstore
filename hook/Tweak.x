#import <UIKit/UIKit.h>

// 声明一个全局的悬浮窗变量，确保其不会被释放
static UIWindow *floatWindow = nil;
static UIButton *floatButton = nil;

// 1. 首先声明 UIApplication 的类别，添加 firstKeyWindow 方法
@interface UIApplication (KeyWindowExtension)
- (UIWindow *)firstKeyWindow;
@end

// 2. 接着声明 SBFloatingWindowDemo 类，确保在调用之前声明
@interface SBFloatingWindowDemo : NSObject
+ (void)createFloatingWindow;
+ (void)floatButtonClicked:(id)sender;
@end

// 3. 实现 UIApplication 的类别
@implementation UIApplication (KeyWindowExtension)

- (UIWindow *)firstKeyWindow {
    if (@available(iOS 13.0, *)) {
		/*
        for (UIWindowScene *scene in self.connectedScenes) {
            if (scene.activationState == UISceneActivationStateForegroundActive) {
                for (UIWindow *window in scene.windows) {
                    if (window.isKeyWindow) {
                        return window;
                    }
                }
            }
        }
		*/
		//屏幕面积
		CGRect screenBounds = [UIScreen mainScreen].bounds;
		CGFloat screenArea = screenBounds.size.width * screenBounds.size.height;
		NSLog(@"屏幕尺寸: %f ,%f",screenBounds.size.width,screenBounds.size.height);
		
		UIApplication *app = [UIApplication sharedApplication];
    
		// 优先尝试获取应用程序委托的窗口（这通常是主窗口）
		if (app.delegate && [app.delegate respondsToSelector:@selector(window)]) {
		        UIWindow *delegateWindow = [app.delegate window];
		        if (delegateWindow && 
		            CGRectEqualToRect(delegateWindow.bounds, [UIScreen mainScreen].bounds)) {
					NSLog(@"找到窗口,使用委托窗口");
		            //return delegateWindow;
		        }
		}
		
		NSSet<UIScene *> *connectedScenes = app.connectedScenes;
		for (UIScene *scene in connectedScenes) {
			//只处理前台活跃的窗口场景
			if (scene.activationState == UISceneActivationStateForegroundActive && [scene isKindOfClass:[UIWindowScene class]]) {
				UIWindowScene *windowScene = (UIWindowScene *)scene;
				for (UIWindow *window in windowScene.windows) {
					NSLog(@"窗口类: %@, 层级: %f, 大小: %@, 隐藏: %d", 
					      NSStringFromClass([window class]), 
					      window.windowLevel, 
					      NSStringFromCGRect(window.bounds), 
					      window.hidden);
                    if (window.isKeyWindow) {					
						//窗口面积
						CGFloat windowArea = window.bounds.size.width * window.bounds.size.height;
						if(windowArea > screenArea * 0.8) {
							NSLog(@"找到窗口,尺寸:---->");
							return window;
						}
                    }
				}
			}
		}
		
		/*
		for (UIScene *scene in [UIApplication sharedApplication].connectedScenes) {
		            if (scene.activationState == UISceneActivationStateForegroundActive &&
		                [scene isKindOfClass:[UIWindowScene class]]) {
		                UIWindowScene *windowScene = (UIWindowScene *)scene;
		                for (UIWindow *window in windowScene.windows) {
		                    if (window.isKeyWindow) {
		                        //mainWindow = window;
		                        //break;
								//return window
								
								//窗口面积
								CGFloat windowArea = window.bounds.size.width * window.bounds.size.height;
								if(windowArea > screenArea * 0.8) {
									NSLog(@"找到窗口,尺寸:---->");
									return window;
								}
		                    }
		                }
		            }
		}
		*/
    } else {
        // Fallback on earlier versions
		NSLog(@"没找到窗口");
        return self.keyWindow;
    }
	NSLog(@"没找到窗口2");
    return self.windows.firstObject; // 如果没有找到keyWindow，返回第一个窗口
}

@end

// 4. 实现 SBFloatingWindowDemo 类
@implementation SBFloatingWindowDemo

+ (void)createFloatingWindow {
    if (floatWindow) return;
    
    // 1. 创建悬浮窗Window
    CGRect screenBounds = UIScreen.mainScreen.bounds;
    floatWindow = [[UIWindow alloc] initWithFrame:CGRectMake(screenBounds.size.width - 70, screenBounds.size.height / 2, 60, 60)];
    // 设置窗口层级，确保它在最上面
    floatWindow.windowLevel = UIWindowLevelAlert + 999; // 非常高的层级
    floatWindow.backgroundColor = UIColor.clearColor;
    floatWindow.hidden = NO; // 必须设置为NO
    floatWindow.userInteractionEnabled = YES;
    // 防止它成为keyWindow，避免影响主App输入
    floatWindow.rootViewController = [UIViewController new];
    //floatWindow.rootViewController.view.backgroundColor = UIColor.clearColor;
	floatWindow.rootViewController.view.backgroundColor = UIColor.greenColor;
    
    // 2. 创建悬浮按钮
    floatButton = [UIButton buttonWithType:UIButtonTypeCustom];
    floatButton.frame = CGRectMake(0, 0, 60, 60);
    floatButton.backgroundColor = [UIColor colorWithRed:0.2 green:0.6 blue:1.0 alpha:0.8];
    floatButton.layer.cornerRadius = 30; // 圆形按钮
    floatButton.layer.masksToBounds = YES;
    floatButton.layer.borderColor = UIColor.whiteColor.CGColor;
    floatButton.layer.borderWidth = 2.0;
    [floatButton setTitle:@"设" forState:UIControlStateNormal];
    [floatButton setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    [floatButton addTarget:self action:@selector(floatButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
    
    // 3. 给按钮添加拖拽手势
    UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePanGesture:)];
    [floatButton addGestureRecognizer:pan];
    
    // 4. 将按钮添加到窗口
    [floatWindow addSubview:floatButton];
}

+ (void)floatButtonClicked:(id)sender {
    // 这里是点击事件！你可以在这里做任何事：
    NSLog(@"悬浮窗被点击了！");
    // 例如：弹出一个alert
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"悬浮窗菜单" message:@"请选择操作" preferredStyle:UIAlertControllerStyleActionSheet];
    [alert addAction:[UIAlertAction actionWithTitle:@"操作一" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        NSLog(@"执行操作一");
    }]];
    [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    
    // 使用我们新增的 firstKeyWindow 方法获取窗口
    UIWindow *keyWindow = [[UIApplication sharedApplication] firstKeyWindow];
    UIViewController *topVC = keyWindow.rootViewController;
    while (topVC.presentedViewController) {
        topVC = topVC.presentedViewController;
    }
    [topVC presentViewController:alert animated:YES completion:nil];
}

+ (void)handlePanGesture:(UIPanGestureRecognizer *)panGesture {
    CGPoint translation = [panGesture translationInView:floatWindow];
    CGPoint originalCenter = floatButton.center;
    CGPoint newCenter = CGPointMake(originalCenter.x + translation.x, originalCenter.y + translation.y);
    
    // 限制悬浮窗不超出屏幕边缘
    CGFloat halfWidth = floatButton.bounds.size.width / 2;
    CGFloat halfHeight = floatButton.bounds.size.height / 2;
    CGRect screenBounds = UIScreen.mainScreen.bounds;
    
    newCenter.x = MAX(halfWidth, MIN(screenBounds.size.width - halfWidth, newCenter.x));
    newCenter.y = MAX(halfHeight + 20, MIN(screenBounds.size.height - halfHeight, newCenter.y)); // 考虑状态栏
    
    floatButton.center = newCenter;
    [panGesture setTranslation:CGPointZero inView:floatWindow];
    
    // 松手时判断贴边
    if (panGesture.state == UIGestureRecognizerStateEnded) {
        BOOL shouldGoLeft = newCenter.x < screenBounds.size.width / 2;
        
        // 动画贴边
        [UIView animateWithDuration:0.3 animations:^{
            CGPoint targetCenter = newCenter;
            targetCenter.x = shouldGoLeft ? halfWidth : (screenBounds.size.width - halfWidth);
            floatButton.center = targetCenter;
        }];
    }
}

@end

// 5. 最后定义 %ctor
%ctor {
    @autoreleasepool {
        // 确保在主线程执行UI操作
        dispatch_async(dispatch_get_main_queue(), ^{
            // 使用我们新增的 firstKeyWindow 方法获取窗口
            UIWindow *mainWindow = [[UIApplication sharedApplication] firstKeyWindow];
            if (!mainWindow) {
                // 如果keyWindow暂时不存在，可以稍后重试
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [SBFloatingWindowDemo createFloatingWindow];
                });
            } else {
                [SBFloatingWindowDemo createFloatingWindow];
            }
        });
    }
}

%hook AppDelegate // 这里hook一个应用肯定会有的类，确保我们的%ctor被执行
// 可以不需要做任何事，只是为了触发加载
%end
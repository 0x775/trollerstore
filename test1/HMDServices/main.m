#import <UIKit/UIKit.h>
#import <FrontBoardServices/FrontBoardServices.h>
#import <objc/runtime.h>
#import <objc/message.h>

// 定义截图服务协议
@protocol HMDScreenshotServiceProtocol <NSObject>
- (void)takeScreenshotWithCompletion:(void (^)(NSData *imageData))completion;
@end

@interface HMDServicesAppDelegate : UIResponder <UIApplicationDelegate, NSXPCListenerDelegate>
@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) NSXPCListener *listener;
@end

@implementation HMDServicesAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    NSLog(@"HMDServices 启动...");
    
    // 隐藏窗口，后台运行
    self.window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    self.window.hidden = YES;
    
    // 注册XPC服务
    [self setupXPCService];
    
    NSLog(@"HMDServices 已启动并注册 XPC 服务");
    
    // 保持应用运行
    [[NSRunLoop currentRunLoop] run];
    
    return YES;
}

- (void)setupXPCService {
    NSLog(@"设置 XPC 服务...");
    
    // 创建XPC监听器
    self.listener = [[NSXPCListener alloc] initWithMachServiceName:@"com.yourcompany.HMDServices"];
    self.listener.delegate = self;
    [self.listener resume];
    
    NSLog(@"XPC 监听器已启动");
}

#pragma mark - NSXPCListenerDelegate

- (BOOL)listener:(NSXPCListener *)listener shouldAcceptNewConnection:(NSXPCConnection *)newConnection {
    NSLog(@"接受新的 XPC 连接");
    
    // 设置XPC接口
    newConnection.exportedInterface = [NSXPCInterface interfaceWithProtocol:@protocol(HMDScreenshotServiceProtocol)];
    newConnection.exportedObject = self;
    [newConnection resume];
    
    return YES;
}

#pragma mark - HMDScreenshotServiceProtocol

- (void)takeScreenshotWithCompletion:(void (^)(NSData *))completion {
    NSLog(@"接收到截图请求");
    
    // 使用运行时调用私有方法进行截图
    Class fbSystemServiceClass = objc_getClass("FBSSystemService");
    if (fbSystemServiceClass) {
        SEL sharedServiceSel = NSSelectorFromString(@"sharedService");
        if ([fbSystemServiceClass respondsToSelector:sharedServiceSel]) {
            id systemService = ((id (*)(Class, SEL))objc_msgSend)(fbSystemServiceClass, sharedServiceSel);
            
            // 尝试不同的私有截图方法
            SEL screenshotSel = NSSelectorFromString(@"takeScreenshotWithOptions:withCompletion:");
            if ([systemService respondsToSelector:screenshotSel]) {
                NSLog(@"使用 takeScreenshotWithOptions:withCompletion: 方法");
                
                // 调用截图方法
                NSDictionary *options = @{};
                void (^screenshotBlock)(id) = ^(id result) {
                    if (result && [result isKindOfClass:[UIImage class]]) {
                        NSData *imageData = UIImagePNGRepresentation((UIImage *)result);
                        NSLog(@"截图成功");
                        completion(imageData);
                    } else {
                        NSLog(@"截图失败: 无效的结果");
                        completion(nil);
                    }
                };
                
                ((void (*)(id, SEL, NSDictionary *, void (^)(id)))objc_msgSend)(
                    systemService, 
                    screenshotSel, 
                    options, 
                    screenshotBlock
                );
                return;
            }
            
            // 尝试其他可能的截图方法
            screenshotSel = NSSelectorFromString(@"takeScreenshot:");
            if ([systemService respondsToSelector:screenshotSel]) {
                NSLog(@"使用 takeScreenshot: 方法");
                
                void (^screenshotBlock)(id) = ^(id result) {
                    if (result && [result isKindOfClass:[UIImage class]]) {
                        NSData *imageData = UIImagePNGRepresentation((UIImage *)result);
                        NSLog(@"截图成功");
                        completion(imageData);
                    } else {
                        NSLog(@"截图失败: 无效的结果");
                        completion(nil);
                    }
                };
                
                ((void (*)(id, SEL, void (^)(id)))objc_msgSend)(
                    systemService, 
                    screenshotSel, 
                    screenshotBlock
                );
                return;
            }
        }
    }
    
    NSLog(@"所有截图方法都失败");
    completion(nil);
}

@end

int main(int argc, char *argv[]) {
    @autoreleasepool {
        NSLog(@"HMDServices 主函数启动");
        return UIApplicationMain(argc, argv, nil, NSStringFromClass([HMDServicesAppDelegate class]));
    }
}
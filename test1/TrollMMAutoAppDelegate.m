#import "TrollMMAutoAppDelegate.h"
#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#import <objc/message.h>
#import <spawn.h> // 添加这行
#import <dlfcn.h> // 添加这行

// 定义截图服务协议
@protocol HMDScreenshotServiceProtocol <NSObject>
- (void)takeScreenshotWithCompletion:(void (^)(NSData *imageData))completion;
@end

@interface TrollMMAutoAppDelegate ()
@property (nonatomic, strong) NSXPCConnection *screenshotServiceConnection;
@end

@implementation TrollMMAutoAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    NSLog(@"didFinishLaunchingWithOptions 启动 ...");
    
    self.window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    self.window.backgroundColor = [UIColor whiteColor];
    
    // 创建简单的UI
    UIViewController *rootVC = [[UIViewController alloc] init];
    rootVC.view.backgroundColor = [UIColor whiteColor];
    
    UIButton *testButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [testButton setTitle:@"测试截图" forState:UIControlStateNormal];
    [testButton addTarget:self action:@selector(testScreenshot) forControlEvents:UIControlEventTouchUpInside];
    testButton.frame = CGRectMake(0, 0, 200, 50);
    testButton.center = CGPointMake(self.window.bounds.size.width/2, self.window.bounds.size.height/2);
    [rootVC.view addSubview:testButton];
    
    self.window.rootViewController = rootVC;
    [self.window makeKeyAndVisible];
    
    // 启动服务应用
    [self startServiceApp];
    
    // 连接到截图服务
    [self connectToScreenshotService];
    
    return YES;
}

- (void)startServiceApp {
    NSLog(@"启动服务应用...");
    
    // 获取服务应用的路径
    NSString *servicePath = [[NSBundle mainBundle] pathForResource:@"HMDServices/HMDServices" ofType:nil];
    if (!servicePath) {
        NSLog(@"错误: 找不到服务应用的可执行文件");
        return;
    }
    
    NSLog(@"服务应用路径: %@", servicePath);
    
    // 方法1: 使用 posix_spawn (iOS 可用)
    pid_t pid;
    const char* path = [servicePath UTF8String];
    char* const args[] = { (char*)[servicePath UTF8String], NULL };
    char* const env[] = { NULL };
    
    int status = posix_spawn(&pid, path, NULL, NULL, args, env);
    if (status == 0) {
        NSLog(@"服务应用启动成功, PID: %d", pid);
        return;
    } else {
        NSLog(@"posix_spawn 启动失败, 错误码: %d", status);
    }
    
    // 方法2: 使用 fork() 和 execve() (iOS 可用)
    pid_t fork_pid = fork();
    if (fork_pid == 0) {
        // 子进程
        char *args[] = { (char*)[servicePath UTF8String], NULL };
        char *env[] = { NULL };
        execve([servicePath UTF8String], args, env);
        exit(1); // 如果 execve 失败
    } else if (fork_pid > 0) {
        // 父进程
        NSLog(@"使用 fork/execve 启动服务应用, PID: %d", fork_pid);
        return;
    } else {
        NSLog(@"fork() 失败");
    }
    
    // 方法3: 直接集成截图功能到主应用
    NSLog(@"所有启动方法都失败，将直接使用主应用截图功能");
}

- (void)connectToScreenshotService {
    NSLog(@"连接到截图服务...");
    
    // 创建XPC连接
    self.screenshotServiceConnection = [[NSXPCConnection alloc] initWithMachServiceName:@"com.yourcompany.HMDServices" options:0];
    
    // 设置远程对象接口
    self.screenshotServiceConnection.remoteObjectInterface = [NSXPCInterface interfaceWithProtocol:@protocol(HMDScreenshotServiceProtocol)];
    
    // 设置连接中断和失效处理
    __weak typeof(self) weakSelf = self;
    self.screenshotServiceConnection.interruptionHandler = ^{
        NSLog(@"服务连接中断");
        weakSelf.screenshotServiceConnection = nil;
    };
    
    self.screenshotServiceConnection.invalidationHandler = ^{
        NSLog(@"服务连接无效");
        weakSelf.screenshotServiceConnection = nil;
        
        // 尝试重新连接
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [weakSelf connectToScreenshotService];
        });
    };
    
    [self.screenshotServiceConnection resume];
    
    NSLog(@"XPC 连接已建立");
}

- (void)testScreenshot {
	NSLog(@"测试截图...++++++");
	/*
    // 首先尝试通过XPC服务截图
    id<HMDScreenshotServiceProtocol> service = [self.screenshotServiceConnection remoteObjectProxyWithErrorHandler:^(NSError * _Nonnull error) {
        NSLog(@"获取远程对象错误: %@", error);
        
        // 如果XPC服务不可用，直接使用主应用截图
        [self takeScreenshotDirectly];
    }];
    
    [service takeScreenshotWithCompletion:^(NSData *imageData) {
        if (imageData) {
            [self handleScreenshotData:imageData];
        } else {
            // 如果XPC服务失败，直接使用主应用截图
            [self takeScreenshotDirectly];
        }
    }];
	*/
	[self takeScreenshotDirectly];
}

- (void)takeScreenshotDirectly {
    NSLog(@"直接使用主应用截图...");
    
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
                        [self handleScreenshotData:imageData];
                    } else {
                        NSLog(@"截图失败: 无效的结果");
                        [self showAlertWithTitle:@"失败" message:@"截图失败"];
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
                        [self handleScreenshotData:imageData];
                    } else {
                        NSLog(@"截图失败: 无效的结果");
                        [self showAlertWithTitle:@"失败" message:@"截图失败"];
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
    
    // 如果所有方法都失败，尝试使用替代方案
    [self takeScreenshotAlternative];
}

- (void)takeScreenshotAlternative {
    // 尝试使用其他私有API进行截图
    // 这里使用UIScreen的私有方法
    UIScreen *mainScreen = [UIScreen mainScreen];
    SEL screenshotSel = NSSelectorFromString(@"takeScreenshot");
    
    if ([mainScreen respondsToSelector:screenshotSel]) {
        // 调用截图方法
        UIImage *screenshot = ((UIImage * (*)(id, SEL))objc_msgSend)(mainScreen, screenshotSel);
        if (screenshot) {
            NSData *imageData = UIImagePNGRepresentation(screenshot);
            [self handleScreenshotData:imageData];
            return;
        }
    }
    
    // 如果所有方法都失败，显示错误
    NSLog(@"所有截图方法都失败");
    [self showAlertWithTitle:@"失败" message:@"无法截图，所有方法都失败"];
}

- (void)handleScreenshotData:(NSData *)imageData {
    // 保存截图到相册
    UIImage *image = [UIImage imageWithData:imageData];
    UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil);
    NSLog(@"截图成功并保存到相册");
    
    // 显示成功提示
    [self showAlertWithTitle:@"成功" message:@"截图已保存到相册"];
}

- (void)showAlertWithTitle:(NSString *)title message:(NSString *)message {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:title
                                                                       message:message
                                                                preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:nil]];
        [self.window.rootViewController presentViewController:alert animated:YES completion:nil];
    });
}

@end
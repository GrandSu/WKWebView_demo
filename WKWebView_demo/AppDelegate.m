//
//  AppDelegate.m
//  WKWebView_demo
//
//  Created by bet001 on 2018/8/24.
//  Copyright © 2018年 GrandSu. All rights reserved.
//

#import "AppDelegate.h"

@interface AppDelegate ()
@property (nonatomic, strong) WebViewController *webVC;

@end

@implementation AppDelegate

- (WebViewController *)webVC {
    if (!_webVC) {
        _webVC = [[WebViewController alloc] init];
    }
    return _webVC;
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
    // RealReachability状态网络监听
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        GLobalRealReachability.hostForPing = @"www.baidu.com";
        GLobalRealReachability.hostForCheck = @"www.apple.com";
        [GLobalRealReachability startNotifier];
    });
    
    UINavigationController *naVC = [[UINavigationController alloc] initWithRootViewController:self.webVC];
    
    self.window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    [self.window setRootViewController:naVC];
    
    // 让当前 UIWindow 窗口变成 keyWiindow (主窗口)，并显示出来
    [self.window makeKeyAndVisible];
    
    return YES;
}


- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
}


- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}


- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
}


- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}


- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}


@end

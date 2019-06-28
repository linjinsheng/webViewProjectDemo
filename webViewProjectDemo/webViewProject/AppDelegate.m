//
//  AppDelegate.m
//  webViewProject
//
//  Created by nickwong on 16/10/18.
//  Copyright © 2016年 nickwong. All rights reserved.
//

#import "AppDelegate.h"
#import <Foundation/Foundation.h>
#import "WebViewController.h"
#import "WXApiObject.h"

//  WXAppId和WXAppSecret
#define WXAppId @"wxff5d0263d7b49d13"
#define WXAppSecret @"4ae6446d4a1490fb5897d40b79d32cd9"

@interface AppDelegate ()<WXApiDelegate>
{
    enum WXScene _scene;
}

@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
    [WXApi registerApp:WXAppId withDescription:@"Wechat"];
    //  1.创建窗口
    self.window = [[UIWindow alloc] init];
    self.window.backgroundColor = [UIColor whiteColor];
    self.window.frame = [UIScreen mainScreen].bounds;
    
    //  2.设置窗口的根控制器
    WebViewController *WebVC = [[WebViewController alloc] init];
    self.window.rootViewController = WebVC;
    
    //  3.显示窗口(成为主窗口)
    [self.window makeKeyAndVisible];
    return YES;
}

- (BOOL)application:(UIApplication *)app openURL:(NSURL *)url options:(NSDictionary<NSString *,id> *)options
{
    
    [WXApi handleOpenURL:url delegate:self];
    
    return YES;
}

- (BOOL)application:(UIApplication *)application handleOpenURL:(NSURL *)url
{
    [WXApi handleOpenURL:url delegate:self];
    return YES;
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
    [WXApi handleOpenURL:url delegate:self];
    return YES;
}


// 授权后回调
- (void)onResp:(BaseResp *)resp {
    
    if([resp isKindOfClass:[SendMessageToWXResp class]])
    {
        NSString *strMsg = [NSString stringWithFormat:@"errcode:%d", resp.errCode];
        NSLog(@"分享返回的strMsg%@",strMsg);
        NSString *shareResult = [NSString stringWithFormat:@"%d", resp.errCode];
        NSLog(@"分享返回的shareResult%@",shareResult);
    }
}


- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end

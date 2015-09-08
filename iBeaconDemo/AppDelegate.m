//
//  AppDelegate.m
//  iBeaconDemo
//
//  Created by oceanwing on 15/7/6.
//  Copyright (c) 2015年 oceanwing. All rights reserved.
//

#import "AppDelegate.h"
#import "BluetoothManager.h"

@import CoreLocation;

@interface AppDelegate ()<CLLocationManagerDelegate>
{
    UIBackgroundTaskIdentifier _backgroundTask;
//    Boolean _inBackground;
}

@property (nonatomic, strong) BluetoothManager *btManager;

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
    application.applicationIconBadgeNumber = 0;
    
    if ([application respondsToSelector:@selector(registerUserNotificationSettings:)])
    {
        [application registerUserNotificationSettings:[UIUserNotificationSettings settingsForTypes:UIUserNotificationTypeAlert|UIUserNotificationTypeBadge|UIUserNotificationTypeSound categories:nil]];
    }

    _backgroundTask = UIBackgroundTaskInvalid;
    _inBackground = YES;
    
    //读取设备电量
    [UIDevice currentDevice].batteryMonitoringEnabled = YES;
    CGFloat batteryLevel = [UIDevice currentDevice].batteryLevel;
    NSLog(@"电量: %3.2f%%", batteryLevel*100);
    
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {

}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    
    [self sendLocalNotificationWithMessage:@"applicationDidEnterBackground"];
    
    [self extendBackgroundRunningTime];
    _inBackground = YES;
    
//    if (!self.btManager) {
//        self.btManager = [[BluetoothManager alloc] init];
//    }
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    
    _inBackground = NO;
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

- (void)application:(UIApplication *)application didReceiveLocalNotification:(UILocalNotification *)notification
{
    application.applicationIconBadgeNumber = 1;
}

- (void)sendLocalNotificationWithMessage:(NSString *)message
{
    UILocalNotification *notification = [[UILocalNotification alloc] init];
    notification.alertBody = message;
    notification.soundName = @"Default";
    [[UIApplication sharedApplication] presentLocalNotificationNow:notification];
}

- (void)extendBackgroundRunningTime {
    if (_backgroundTask != UIBackgroundTaskInvalid) {
        // if we are in here, that means the background task is already running.
        // don't restart it.
        return;
    }

    [self sendLocalNotificationWithMessage:@"Attempting to extend background running time"];
    
    __block Boolean self_terminate = YES;
    
    _backgroundTask = [[UIApplication sharedApplication] beginBackgroundTaskWithName:@"DummyTask" expirationHandler:^{
        NSLog(@"Background task expired by iOS");
        [self sendLocalNotificationWithMessage:@"Background task expired by iOS"];
        if (self_terminate) {
            [[UIApplication sharedApplication] endBackgroundTask:_backgroundTask];
            _backgroundTask = UIBackgroundTaskInvalid;
        }
    }];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSLog(@"Background task started");
        
        while (true) {
            NSLog(@"background time remaining: %8.2f", [UIApplication sharedApplication].backgroundTimeRemaining);
            [NSThread sleepForTimeInterval:1];
        }
        
    });
}

@end

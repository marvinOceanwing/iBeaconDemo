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
    Boolean _inBackground;
}

@property (nonatomic, strong) CLLocationManager *locationManager;
@property (nonatomic, strong) BluetoothManager *btManager;
@property (nonatomic, strong) CLBeaconRegion *mRegion;

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    
    application.applicationIconBadgeNumber = 0;
    self.locationManager = [[CLLocationManager alloc] init];
    self.locationManager.delegate = self;
    
    if ([application respondsToSelector:@selector(registerUserNotificationSettings:)])
    {
        [application registerUserNotificationSettings:[UIUserNotificationSettings settingsForTypes:UIUserNotificationTypeAlert|UIUserNotificationTypeBadge|UIUserNotificationTypeSound categories:nil]];
    }
    
    NSUUID *uuid = [[NSUUID alloc] initWithUUIDString:@"FDA50693-A4E2-4FB1-AFCF-C6EB07647825"];
    _mRegion = [[CLBeaconRegion alloc] initWithProximityUUID:uuid identifier:[[NSBundle mainBundle] bundleIdentifier]];
    _mRegion.notifyEntryStateOnDisplay = YES;
    
    [_locationManager startMonitoringForRegion:_mRegion];
//    [_locationManager stopRangingBeaconsInRegion:_mRegion];
//    [_locationManager startRangingBeaconsInRegion:_mRegion];
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
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    
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

#pragma mark CLLocationManagerDelegate

- (void)locationManager:(CLLocationManager *)manager didEnterRegion:(CLRegion *)region
{
    if ([region isKindOfClass:[CLBeaconRegion class]]) {
        [self sendLocalNotificationWithMessage:@"You enter iBeacon region."];
        [self networkRequest];
//        self.btManager = [[BluetoothManager alloc] init];
        
        [_locationManager startRangingBeaconsInRegion:(CLBeaconRegion *)region];
        
//        if (_inBackground) {
//            [self extendBackgroundRunningTime];
//        }
    }
}

- (void)locationManager:(CLLocationManager *)manager didExitRegion:(CLRegion *)region {
    if ([region isKindOfClass:[CLBeaconRegion class]]) {

        [self sendLocalNotificationWithMessage:@"You exit iBeacon region."];
        [self networkRequest];
    }
}

- (void)locationManager:(CLLocationManager *)manager didRangeBeacons:(NSArray *)beacons inRegion:(CLBeaconRegion *)region
{
    static NSInteger num = 0;
    num ++;
    if (num % 2 == 0 && beacons.count > 0) {
        CLBeacon *beacon = [beacons objectAtIndex:0];
        NSString *str = [NSString stringWithFormat:@"%@, %0.2fm", beacon.proximityUUID.UUIDString, beacon.accuracy];
        [self sendLocalNotificationWithMessage:str];
    }
}

- (void)locationManager:(CLLocationManager *)manager didDetermineState:(CLRegionState)state forRegion:(CLRegion *)region
{
    if (state == CLRegionStateInside) {
        [self sendLocalNotificationWithMessage:@"Region state inside"];
    } else if (state == CLRegionStateOutside) {
        [self sendLocalNotificationWithMessage:@"Region state outside"];
    } else {
        
    }
    
//    if (_inBackground) {
//        [self extendBackgroundRunningTime];
//    }
}

- (void)networkRequest
{
    NSURLRequest *request = [[NSURLRequest alloc] initWithURL:[NSURL URLWithString:@"https://baidu.com"]];
    NSOperationQueue *queue = [[NSOperationQueue alloc]init];
    [NSURLConnection sendAsynchronousRequest:request queue:queue completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
        if (!connectionError) {
            [self sendLocalNotificationWithMessage:@"Network request successfully."];
        }
    }];
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
    NSLog(@"Attempting to extend background running time");
    
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

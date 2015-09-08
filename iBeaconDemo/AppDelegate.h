//
//  AppDelegate.h
//  iBeaconDemo
//
//  Created by oceanwing on 15/7/6.
//  Copyright (c) 2015年 oceanwing. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (nonatomic) BOOL inBackground;

- (void)extendBackgroundRunningTime;

@end


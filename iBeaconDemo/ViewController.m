//
//  ViewController.m
//  iBeaconDemo
//
//  Created by oceanwing on 15/7/6.
//  Copyright (c) 2015年 oceanwing. All rights reserved.
//

#import "ViewController.h"
#import <CoreLocation/CoreLocation.h>

@interface ViewController ()<CLLocationManagerDelegate>

@property (nonatomic, strong) CLLocationManager *mLocalManager;
@property (nonatomic, strong) CLBeaconRegion *mRegion;

@property (nonatomic, weak) IBOutlet UIButton *clientIBeaconBtn;
@property (nonatomic, weak) IBOutlet UILabel *label;
@property (nonatomic, weak) IBOutlet UITextView *textView;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    _mLocalManager = [[CLLocationManager alloc] init];
    // New iOS 8 request for Always Authorization, required for iBeacons to work!
    if([_mLocalManager respondsToSelector:@selector(requestAlwaysAuthorization)]) {
        [_mLocalManager requestAlwaysAuthorization];
    }
    _mLocalManager.pausesLocationUpdatesAutomatically = NO;
    _mLocalManager.delegate = self;
    
    NSUUID *uuid = [[NSUUID alloc] initWithUUIDString:@"FDA50693-A4E2-4FB1-AFCF-C6EB07647825"];
    
    _mRegion = [[CLBeaconRegion alloc] initWithProximityUUID:uuid identifier:[[NSBundle mainBundle] bundleIdentifier]];
    
    // launch app when display is turned on and inside region
    _mRegion.notifyEntryStateOnDisplay = YES;
    
}

- (IBAction)buttonClicked:(UIButton *)sender
{
    if ([CLLocationManager isMonitoringAvailableForClass:[CLBeaconRegion class]]) {
        
        if (sender.isSelected) {
            [self.clientIBeaconBtn setTitle:@"打开 iBeacon" forState:UIControlStateNormal];
            [_mLocalManager stopMonitoringForRegion:_mRegion];
            [_mLocalManager stopRangingBeaconsInRegion:_mRegion];
        } else {
            [self.clientIBeaconBtn setTitle:@"关闭 iBeacon" forState:UIControlStateNormal];
            [_mLocalManager startMonitoringForRegion:_mRegion];
            [_mLocalManager startRangingBeaconsInRegion:_mRegion];
            [_mLocalManager requestStateForRegion:_mRegion];

        }
        sender.selected = !sender.selected;
    } else {
        NSLog(@"This device not support iBeacon.");
    }

}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (NSString *)detailsStringForBeacon:(CLBeacon *)beacon
{
    NSString *proximity;
    switch (beacon.proximity) {
        case CLProximityNear:
            proximity = @"Near";
            break;
        case CLProximityImmediate:
            proximity = @"Immediate";
            break;
        case CLProximityFar:
            proximity = @"Far";
            break;
        case CLProximityUnknown:
        default:
            proximity = @"Unknown";
            break;
    }

    NSString *format = @"%@\n major:%@, minor:%@ • %@ • %0.2fm";
    return [NSString stringWithFormat:format, beacon.proximityUUID.UUIDString, beacon.major, beacon.minor, proximity, beacon.accuracy];
}

#pragma mark CLLocationManagerDelegate

- (void)locationManager:(CLLocationManager *)manager didEnterRegion:(CLRegion *)region
{
    self.label.text = @"You enter the iBeacon region";
}

- (void)locationManager:(CLLocationManager *)manager didExitRegion:(CLRegion *)region
{
    self.label.text = @"You exit the iBeacon region";
}

- (void)locationManager:(CLLocationManager *)manager didRangeBeacons:(NSArray *)beacons inRegion:(CLBeaconRegion *)region
{
    NSMutableString *str = [NSMutableString stringWithCapacity:0];
    for (CLBeacon *beacon in beacons) {
        [str appendString:[self detailsStringForBeacon:beacon]];
        [str appendString:@"\n"];
    }
    NSLog(@"str = %@", str);
    self.textView.text = str;
}

@end

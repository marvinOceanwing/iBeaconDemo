//
//  ViewController.m
//  iBeaconDemo
//
//  Created by oceanwing on 15/7/6.
//  Copyright (c) 2015年 oceanwing. All rights reserved.
//

#import "ViewController.h"
#import <CoreLocation/CoreLocation.h>
#import "BluetoothManager.h"
#import "AppDelegate.h"

@interface ViewController ()<CLLocationManagerDelegate>

@property (nonatomic, strong) CLLocationManager *mLocalManager;
@property (nonatomic, strong) CLBeaconRegion *mRegion;

@property (nonatomic, strong) NSArray *beaconArray;
@property (nonatomic, strong) BluetoothManager *btManager;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.beaconArray = [[NSArray alloc] init];

    _mLocalManager = [[CLLocationManager alloc] init];
    // New iOS 8 request for Always Authorization, required for iBeacons to work!
    if([_mLocalManager respondsToSelector:@selector(requestAlwaysAuthorization)]) {
        [_mLocalManager requestAlwaysAuthorization];
    }
    _mLocalManager.pausesLocationUpdatesAutomatically = NO;
    _mLocalManager.delegate = self;
    
    NSUUID *uuid = [[NSUUID alloc] initWithUUIDString:@"FDA50693-A4E2-4FB1-AFCF-C6EB07647825"]; //819C3799-348C-212A-68AF-FD79DAC5A455
    
    _mRegion = [[CLBeaconRegion alloc] initWithProximityUUID:uuid identifier:[[NSBundle mainBundle] bundleIdentifier]];
    
    // launch app when display is turned on and inside region
    _mRegion.notifyEntryStateOnDisplay = YES;
}

- (void)viewDidAppear:(BOOL)animated
{
    [self sendLocalNotificationWithMessage:@"viewDidAppear"];
    [super viewDidAppear:animated];
    [_mLocalManager startUpdatingLocation];
    
    [_mLocalManager startMonitoringForRegion:_mRegion];
    [_mLocalManager startRangingBeaconsInRegion:_mRegion];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    [_mLocalManager stopUpdatingLocation];
    
    [_mLocalManager stopMonitoringForRegion:_mRegion];
    [_mLocalManager stopRangingBeaconsInRegion:_mRegion];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.beaconArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIdentifier = @"cellIdentifier";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellIdentifier];
    }
    CLBeacon *beacon = [self.beaconArray objectAtIndex:indexPath.row];
    cell.textLabel.text = [beacon proximityUUID].UUIDString;
    
    cell.detailTextLabel.text = [self detailsStringForBeacon:beacon];
    
    return cell;
}

#pragma mark UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    
}

#pragma mark CLLocationManagerDelegate

//- (void)locationManager:(CLLocationManager *)manager didDetermineState:(CLRegionState)state forRegion:(CLRegion *)region
//{
//    if (state == CLRegionStateInside) {
//        [self sendLocalNotificationWithMessage:@"Region state inside"];
//    } else if (state == CLRegionStateOutside) {
//        [self sendLocalNotificationWithMessage:@"Region state outside"];
//    } else {
//        
//    }
//}

- (void)locationManager:(CLLocationManager *)manager didEnterRegion:(CLRegion *)region
{
    if ([region isKindOfClass:[CLBeaconRegion class]]) {
        [self sendLocalNotificationWithMessage:@"You enter iBeacon region."];
        NSLog(@"You enter the iBeacon region");
        [self networkRequest];
    }
    
    _btManager = [[BluetoothManager alloc] init];
    
    AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    if (appDelegate.inBackground) {
        [appDelegate extendBackgroundRunningTime];
    }
}

- (void)locationManager:(CLLocationManager *)manager didExitRegion:(CLRegion *)region
{
    if ([region isKindOfClass:[CLBeaconRegion class]]) {
        [self sendLocalNotificationWithMessage:@"You exit iBeacon region."];
        NSLog(@"You exit the iBeacon region");
        [self networkRequest];
    }
    
}

- (void)locationManager:(CLLocationManager *)manager didRangeBeacons:(NSArray *)beacons inRegion:(CLBeaconRegion *)region
{    
    self.beaconArray = beacons;
    [self.tableView reloadData];
    
    static NSInteger num = 0;
    num ++;
    if (num % 10 == 0 && beacons.count > 0) {
        CLBeacon *beacon = [beacons objectAtIndex:0];
        NSString *str = [NSString stringWithFormat:@"%@, %0.2fm", beacon.proximityUUID.UUIDString, beacon.accuracy];
//        NSLog(@"%@", str);
        [self sendLocalNotificationWithMessage:str];
    }
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations
{
    CLLocation *location = [locations lastObject];
    NSString *str = [NSString stringWithFormat:@"latitude=%f, longitude=%f", location.coordinate.latitude, location.coordinate.longitude];
    [self sendLocalNotificationWithMessage:str];

}

#pragma mark - private method

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
    
    NSString *format = @"major:%@, minor:%@ • %@ • %0.2fm • rssi = %d";
    return [NSString stringWithFormat:format, beacon.major, beacon.minor, proximity, beacon.accuracy, beacon.rssi];
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

@end

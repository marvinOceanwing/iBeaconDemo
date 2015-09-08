//
//  BluetoothManager.m
//  iBeaconDemo
//
//  Created by oceanwing on 15/8/25.
//  Copyright (c) 2015年 oceanwing. All rights reserved.
//

#import "BluetoothManager.h"
#import <CoreBluetooth/CoreBluetooth.h>

@interface BluetoothManager()<CBCentralManagerDelegate, CBPeripheralDelegate>

@property (nonatomic, strong) CBCentralManager *centralManager;
@property (nonatomic, strong) CBPeripheral *connectPeripheral;

@end

@implementation BluetoothManager

- (instancetype)init {
    self = [super init];
    if (self) {
        self.centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
    }
    
    return self;
}

#pragma mark - CBCentralManagerDelegate

- (void)centralManagerDidUpdateState:(CBCentralManager *)central
{
    switch (central.state) {
        case CBCentralManagerStatePoweredOff:
            NSLog(@"CoreBluetooth BLE hardware is powered off");
            break;
        case CBCentralManagerStatePoweredOn:
        {
            NSLog(@"CoreBluetooth BLE hardware is powered on and ready");
            [self sendLocalNotificationWithMessage:@"CoreBluetooth is powered on."];
//            [self.centralManager scanForPeripheralsWithServices:nil options:nil];
            
            [self.centralManager scanForPeripheralsWithServices:@[[CBUUID UUIDWithString:@"0xFFF0"]] options:nil];
        }
            break;
        case CBCentralManagerStateResetting:
            NSLog(@"CoreBluetooth BLE hardware is resetting");
            break;
        case CBCentralManagerStateUnauthorized:
            NSLog(@"CoreBluetooth BLE state is unauthorized");
            break;
        case CBCentralManagerStateUnknown:
            NSLog(@"CoreBluetooth BLE state is unknown");
            break;
        case CBCentralManagerStateUnsupported:
            NSLog(@"CoreBluetooth BLE hardware is unsupported on this platform");
            break;
        default:
            break;
    }
}

- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI
{
    _connectPeripheral = peripheral;
    
    NSLog(@"%@", [_connectPeripheral identifier].UUIDString);
//    [self sendLocalNotificationWithMessage:@"Discover perioheral."];
    
    NSString *str = [NSString stringWithFormat:@"identifier = %@", [_connectPeripheral identifier].UUIDString];
    [self sendLocalNotificationWithMessage:str];

    
    static BOOL connectOnePeripheral = NO;
    if (!connectOnePeripheral) {
        connectOnePeripheral = YES;
    
        [self.centralManager stopScan];
        [self.centralManager connectPeripheral:_connectPeripheral options:nil];
    }
}

- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral
{
    NSLog(@"Connection successfull to peripheral: %@",peripheral);
    
    [self sendLocalNotificationWithMessage:@"Connectted perioheral."];
}

- (void)centralManager:(CBCentralManager *)central willRestoreState:(NSDictionary *)dict
{
    [self sendLocalNotificationWithMessage:@"willRestoreState."];
}

- (void)sendLocalNotificationWithMessage:(NSString *)message
{
    UILocalNotification *notification = [[UILocalNotification alloc] init];
    notification.alertBody = message;
    notification.soundName = @"Default";
    [[UIApplication sharedApplication] presentLocalNotificationNow:notification];
}

#pragma mark - public method

- (void)backgroundScanBluetooth
{
    [self.centralManager stopScan];

    NSDictionary *options = @{CBCentralManagerScanOptionAllowDuplicatesKey:[NSNumber numberWithBool:YES]};
    [self.centralManager scanForPeripheralsWithServices:@[[CBUUID UUIDWithString:@"32079F23-7C8F-489A-BA15-6A99A0912EEF"]] options:options];

}

@end

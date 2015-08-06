//
//  BluetoothViewController.h
//  iBeaconDemo
//
//  Created by oceanwing on 15/7/22.
//  Copyright (c) 2015年 oceanwing. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreBluetooth/CoreBluetooth.h>

@interface BluetoothViewController : UIViewController<CBCentralManagerDelegate, CBPeripheralDelegate>

@property (nonatomic, strong) CBCentralManager *centralManager;
@property (nonatomic, strong) CBPeripheral *currentConnectPer;
@property (nonatomic, strong) CBCharacteristic *writeCharacteristic;
@property (nonatomic, strong) CBCharacteristic *readCharcteristic;

@end

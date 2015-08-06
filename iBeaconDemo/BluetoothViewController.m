//
//  BluetoothViewController.m
//  iBeaconDemo
//
//  Created by oceanwing on 15/7/22.
//  Copyright (c) 2015年 oceanwing. All rights reserved.
//

#import "BluetoothViewController.h"

@interface BluetoothViewController ()<UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, weak) IBOutlet UITableView *tableView;
@property (nonatomic, strong) NSMutableArray *cbArray;

@end

@implementation BluetoothViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.cbArray = [NSMutableArray array];
    self.centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
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
    return self.cbArray.count;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return [NSString stringWithFormat:@"Total count = %lu", (unsigned long)self.cbArray.count];
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 40;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIdentifier = @"cellIdentifier";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
    }
    CBPeripheral *currentPer = [self.cbArray objectAtIndex:indexPath.row];
    cell.textLabel.text = currentPer.name ? currentPer.name : @"Not available";
    return cell;
}

#pragma mark UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if (self.currentConnectPer && (self.currentConnectPer.state == CBPeripheralStateConnected)) {
        [self.centralManager cancelPeripheralConnection:self.currentConnectPer];
    }
    
    CBPeripheral *currentPer = [self.cbArray objectAtIndex:indexPath.row];
    [self.centralManager connectPeripheral:currentPer options:nil];
}

#pragma mark - CBCentralManagerDelegate

- (void)centralManagerDidUpdateState:(CBCentralManager *)central
{
    switch (central.state) {
        case CBCentralManagerStatePoweredOff:
            NSLog(@"CoreBluetooth BLE hardware is powered off");
            break;
        case CBCentralManagerStatePoweredOn:
            NSLog(@"CoreBluetooth BLE hardware is powered on and ready");
            [self.centralManager scanForPeripheralsWithServices:nil options:nil];
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
    CBPeripheral *currentPer = peripheral;
    
    if (![self.cbArray containsObject:currentPer]) {
        [self.cbArray addObject:currentPer];
    }
    [self.tableView reloadData];
}

- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral
{
    NSLog(@"Connection successfull to peripheral: %@",peripheral);
    
    self.currentConnectPer = peripheral;
    self.currentConnectPer.delegate = self;
    [self.currentConnectPer discoverServices:nil];
}

- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
    NSLog(@"Connection failed to peripheral: %@",peripheral);
}

#pragma mark - CBPeripheralDelegate

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error
{
    if (error) {
        NSLog(@"Did discover failed!");
        return;
    }
    
    for (CBService *service in peripheral.services) {
        NSLog(@"service.UUID = %@", service.UUID);
        if ([service.UUID isEqual:[CBUUID UUIDWithString:@"FFF0"]]) {
            [peripheral discoverCharacteristics:nil forService:service];
            break;
        }
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error
{
    if (error) {
        NSLog(@"Did discover failed!");
        return;
    }
    
    for (CBCharacteristic *characteristic in service.characteristics) {
        NSLog(@"uuid = %@", characteristic.UUID);
        if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:@"FFF2"]]) {
            self.writeCharacteristic = characteristic;
            break;
        }
    }
    
    for (CBCharacteristic *characteristic in service.characteristics) {
        NSLog(@"uuid = %@", characteristic.UUID);
        if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:@"FFF2"]]) {
            self.readCharcteristic = characteristic;
            [self.currentConnectPer setNotifyValue:YES forCharacteristic:self.readCharcteristic];
            break;
        }
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didWriteValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    if (error) {
        NSLog(@"didWriteValueForCharacteristic error = %@", [error localizedDescription]);
        return;
    }
    NSLog(@"didWriteValueForCharacteristic");
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    if (error) {
        NSLog(@"didUpdateValueForCharacteristic error = %@", [error localizedDescription]);
        return;
    }
    
    NSLog(@"收到的数据：%@",characteristic.value);
}


- (IBAction)sendDataButtonClicked:(id)sender
{
        NSString *paylodMessage = @"Hello World!";
        NSData *paylod = [paylodMessage dataUsingEncoding:NSUTF8StringEncoding];
    [self.currentConnectPer writeValue:paylod forCharacteristic:self.writeCharacteristic type:CBCharacteristicWriteWithResponse];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end

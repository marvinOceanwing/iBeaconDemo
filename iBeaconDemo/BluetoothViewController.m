//
//  BluetoothViewController.m
//  iBeaconDemo
//
//  Created by oceanwing on 15/7/22.
//  Copyright (c) 2015年 oceanwing. All rights reserved.
//

#import "BluetoothViewController.h"

#define SEND_PACKAGE_NUM 100

@interface BluetoothViewController ()<UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, weak) IBOutlet UITableView *tableView;
@property (nonatomic, weak) IBOutlet UITextView *textView;
@property (nonatomic, weak) IBOutlet UITextField *inputTextField;
@property (nonatomic, strong) NSMutableArray *cbArray;
@property (nonatomic, strong) NSMutableArray *messageArray;

@property (nonatomic, assign) NSTimeInterval startSendDateTime; //开始发送时间
@property (nonatomic, assign) NSTimeInterval startReceiveDateTime; //开始接收时间
@property (nonatomic) NSInteger sendNum; //记录发送成功的个数
@property (nonatomic) NSInteger sendCount; //记录发送的个数
@property (nonatomic) NSInteger receivedLength; //记录接收的总长度
@property (nonatomic) NSInteger receivedCount; //记录接收的包个数

@property (nonatomic) NSTimeInterval connectStart; //开始连接时间

@property (nonatomic, strong) UIBarButtonItem *rightItem;
@property (nonatomic, strong) UIBarButtonItem *resetItem;

@end

@implementation BluetoothViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"BLE";
    self.cbArray = [NSMutableArray array];
    self.messageArray = [NSMutableArray array];
    self.receivedLength = 0;
    self.receivedCount = 0;
    self.sendCount = 0;
    self.startReceiveDateTime = 0;
    
    self.textView.editable = NO;
    self.textView.layer.borderWidth = 1;
    self.textView.layer.borderColor = [UIColor grayColor].CGColor;
    
    self.centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:nil options:@{CBCentralManagerOptionRestoreIdentifierKey:@"centralManagerIdentifier"}];
    
    self.rightItem = [[UIBarButtonItem alloc] initWithTitle:@"开始" style:UIBarButtonItemStylePlain target:self action:@selector(startSendDataToBLEDevice:)];
    
    self.resetItem = [[UIBarButtonItem alloc] initWithTitle:@"重置" style:UIBarButtonItemStylePlain target:self action:@selector(resetData)];
    self.navigationItem.rightBarButtonItems = @[_rightItem, _resetItem];
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
    NSString *text = [NSString stringWithFormat:@"%@,  %@", currentPer.name, [currentPer identifier].UUIDString];
    cell.textLabel.text = text;

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
    
    if (currentPer.state == CBPeripheralStateConnected) {
        [self.centralManager cancelPeripheralConnection:currentPer];
    }
    
    [self.centralManager connectPeripheral:currentPer options:nil];
    
    _connectStart = [[NSDate date] timeIntervalSince1970];
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
            [self.centralManager scanForPeripheralsWithServices:nil options:nil];
//            NSDictionary *options = @{CBCentralManagerScanOptionAllowDuplicatesKey:[NSNumber numberWithBool:YES]};
//            [self.centralManager scanForPeripheralsWithServices:@[[CBUUID UUIDWithString:@"FFF0"]] options:options];
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
    CBPeripheral *currentPer = peripheral;
    NSLog(@"didDiscoverPeripheral: %@", peripheral);
    
    if ([[advertisementData allKeys] containsObject:@"kCBAdvDataManufacturerData"]) {
        NSData *data = [advertisementData objectForKey:@"kCBAdvDataManufacturerData"]; //<1e04e0819039>
        
        NSString *str = [self hexStringFromData:data];
        NSLog(@"Mac address = %@", str);
        
        //将1e04e0819039转换为1e:04:e0:81:90:39
        NSInteger loc = 0;
        NSString *macAddress = @"";
        while (loc < str.length) {
            NSString *subStr = [str substringWithRange:NSMakeRange(loc, 2)];
            loc += 2;
            if (macAddress.length == 0) {
                macAddress = [NSString stringWithFormat:@"%@", subStr];
            } else {
                macAddress = [NSString stringWithFormat:@"%@:%@", macAddress, subStr];
            }
        }
        NSLog(@"Mac address = %@", macAddress);
    }
    
    if (![self.cbArray containsObject:currentPer]) {
        [self.cbArray addObject:currentPer];
    }
    [self.tableView reloadData];
}

- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral
{
    NSLog(@"Connection successfull to peripheral: %@",peripheral);
    NSString *str = [NSString stringWithFormat:@"%@ connect succeddfully", peripheral.name];
    [self setTextViewWithString:str];
    
    self.currentConnectPer = peripheral;
    self.currentConnectPer.delegate = self;
//    [self.currentConnectPer discoverServices:nil];
    [self.currentConnectPer discoverServices:@[[CBUUID UUIDWithString:@"18F0"]]]; //FFF0
}

- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
    NSLog(@"Connection failed to peripheral: %@",peripheral);
}

- (void)centralManager:(CBCentralManager *)central willRestoreState:(NSDictionary *)dict
{
//    NSArray *peripherals = dict[CBCentralManagerRestoredStatePeripheralsKey];
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
        if ([service.UUID isEqual:[CBUUID UUIDWithString:@"18F0"]]) { //FFF0
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
        NSLog(@"uuid = %@, properties = %lx", characteristic.UUID, characteristic.properties);
        if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:@"2AF1"]]) { //FFF2
            self.writeCharacteristic = characteristic;
            [self setTextViewWithString:@"Find write Characteristic 2AF1."];
            break;
        }
    }
    
    for (CBCharacteristic *characteristic in service.characteristics) {
        NSLog(@"uuid = %@, properties = %lx", characteristic.UUID, characteristic.properties);
        if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:@"2AF0"]]) { //FFF1
            self.readCharcteristic = characteristic;
            [self setTextViewWithString:@"Find read Characteristic 2AF0."];
            [self.currentConnectPer setNotifyValue:YES forCharacteristic:self.readCharcteristic];
            
            //打印连接时间
//            NSString *connectTime = [NSString stringWithFormat:@"connect time = %.3f", [[NSDate date] timeIntervalSince1970] - _connectStart];
//            [self setTextViewWithString:connectTime];
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
    
    NSString *str = [NSString stringWithFormat:@"write = %ld, totalByte = %ld, time = %.3fs", _sendNum, _sendNum*(_inputTextField.text.length), [[NSDate date] timeIntervalSince1970]-self.startSendDateTime];
    [self setTextViewWithString:str];
    
    if (_sendNum >= SEND_PACKAGE_NUM) {
        self.resetItem.enabled = YES;
        self.rightItem.enabled = YES;
    }
    
    _sendNum ++;
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    if (error) {
        NSLog(@"didUpdateValueForCharacteristic error = %@", [error localizedDescription]);
        return;
    }
    
    //电池电量信息的特征值UUID=“2A19”
    if ([[characteristic UUID] isEqual:[CBUUID UUIDWithString:@"2A19"]]){
        const unsigned char *hexBytesLight = [characteristic.value bytes];
        NSString * battery = [NSString stringWithFormat:@"%02x", hexBytesLight[0]];
        NSLog(@"batteryInfo:%@",battery);
    }
    
    if (_startReceiveDateTime == 0) {
        _startReceiveDateTime = [[NSDate date] timeIntervalSince1970];
    }
    
    NSString *message = [[NSString alloc] initWithData:characteristic.value encoding:NSUTF8StringEncoding];
    _receivedLength += message.length;
    _receivedCount++;
//    NSString *receiveMessage = [NSString stringWithFormat:@"Receive message: %@, count = %ld", message, (long)_receivedLength];
    NSString *receiveMessage = [NSString stringWithFormat:@"Receive Count = %ld, Length = %ld, Time = %.3fs", _receivedCount, _receivedLength, [[NSDate date] timeIntervalSince1970]-_startReceiveDateTime];
    NSLog(@"%@", receiveMessage);
    [self setTextViewWithString:receiveMessage];
}

#pragma mark - private method

- (IBAction)sendDataButtonClicked:(id)sender
{
//    Byte dataArr[2];
//    dataArr[0]=0xaa; dataArr[1]=0xbb;
//    NSData * myData = [NSData dataWithBytes:dataArr length:2];
//
//    [self.currentConnectPer writeValue:myData forCharacteristic:self.writeCharacteristic type:CBCharacteristicWriteWithResponse];
    
    if (_inputTextField.text.length > 0) {
        
        if (self.currentConnectPer.state == CBPeripheralStateConnected) {
            NSString *message = _inputTextField.text;
            NSData *myData = [message dataUsingEncoding:NSUTF8StringEncoding];
            [self.currentConnectPer writeValue:myData forCharacteristic:self.writeCharacteristic type:CBCharacteristicWriteWithResponse];
        } else {
            [self setTextViewWithString:@"Peripheral disconnected."];
        }
        
    } else {

        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"提示" message:@"发送数据不能为空" delegate:nil cancelButtonTitle:@"好" otherButtonTitles:nil, nil];
        [alert show];
    }
}

- (void)resetData
{
    self.startReceiveDateTime = 0;
    self.receivedLength = 0;
    self.receivedCount = 0;
    [self.messageArray removeAllObjects];
    self.textView.text = @"";
    
    if (self.currentConnectPer && (self.currentConnectPer.state == CBPeripheralStateConnected)) {
        [self.centralManager cancelPeripheralConnection:self.currentConnectPer];
        [self setTextViewWithString:@"Peripheral disconnected."];
    }
}

- (void)setTextViewWithString:(NSString *)text
{
    [self.messageArray addObject:text];
    if (self.messageArray.count > 500) {
        [self.messageArray removeObjectsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, 500)]];
    }
    NSString *message = [self.messageArray componentsJoinedByString:@"\n"];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        self.textView.text = message;
    });
}

- (void)startSendDataToBLEDevice:(UIBarButtonItem *)sender
{
    if (self.currentConnectPer && (self.currentConnectPer.state == CBPeripheralStateConnected)) {
        
        if (_inputTextField.text.length == 0) {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"提示" message:@"发送数据不能为空" delegate:nil cancelButtonTitle:@"好" otherButtonTitles:nil, nil];
            [alert show];
            return;
        }
        
        self.sendNum = 1;
        self.sendCount = 1;
        self.startSendDateTime = [[NSDate date] timeIntervalSince1970];
        self.resetItem.enabled = NO;
        self.rightItem.enabled = NO;
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            while (_sendCount <= SEND_PACKAGE_NUM) {
                [self startSendMessage];
                [NSThread sleepForTimeInterval:0.01];
                _sendCount++;
            }
        });
            
    } else {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"提示" message:@"请连接蓝牙后开始" delegate:nil cancelButtonTitle:@"好" otherButtonTitles:nil, nil];
        [alert show];
    
    }
}

- (void)startSendMessage
{
    if (self.currentConnectPer.state == CBPeripheralStateConnected) {
        NSString *message = _inputTextField.text;
        NSData *myData = [message dataUsingEncoding:NSUTF8StringEncoding];
    //    NSLog(@"%lu", (unsigned long)myData.length);
        [self.currentConnectPer writeValue:myData forCharacteristic:self.writeCharacteristic type:CBCharacteristicWriteWithResponse];
    }
}

//data转换为十六进制的字符串。
- (NSString *)hexStringFromData:(NSData *)myD{
    
    Byte *bytes = (Byte *)[myD bytes];
    //下面是Byte 转换为16进制。
    NSString *hexStr=@"";
    
    for(int i=0; i<[myD length]; i++) {
        NSString *newHexStr = [NSString stringWithFormat:@"%x", bytes[i]&0xff]; //16进制数
        
        if([newHexStr length]==1) {
            hexStr = [NSString stringWithFormat:@"%@0%@",hexStr,newHexStr];
        } else {
            hexStr = [NSString stringWithFormat:@"%@%@",hexStr,newHexStr];
        }
    }
    NSLog(@"%@",hexStr);
    
    return hexStr;
}

@end

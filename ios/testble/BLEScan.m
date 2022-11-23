//
//  BLEScan.m
//  PulseApp
//
//  Created by Rishu Agrawal on 19/11/22.
//

#import <Foundation/Foundation.h>
#import "BLEScan.h"

@interface BLEScan() <CBCentralManagerDelegate>

@property (strong, nonatomic) CBCentralManager *manager;
@property CBPeripheral *dot;


@end

@implementation BLEScan

- (instancetype) initModule {
  NSLog(@"BLEScan: init");
  if (self = [super init]) {
    _manager = [[CBCentralManager alloc] initWithDelegate:self queue:dispatch_get_main_queue() options:nil];
    NSLog(@"BLEScan: state %li", (long)_manager.state);
  }
  return self;
}


//-(void) centralManagerDidUpdateState:(CBCentralManager *)central {
//  NSLog(@"BLEScan: centralManagerDidUpdateState ");
//  [self beginSearch];
//}

- (void)centralManagerDidUpdateState:(CBCentralManager *)central {
  // You should test all scenarios
  NSLog(@"BLEScan: state %li", (long)central.state);
  if (central.state != CBManagerStatePoweredOn) {
      return;
  }
   
  if (central.state == CBManagerStatePoweredOn) {
      // Scan for devices
    [_manager scanForPeripheralsWithServices:nil options:@{ CBCentralManagerScanOptionAllowDuplicatesKey : @YES }];
    NSLog(@"Scanning started");
  }
}

-(void) beginSearch  {
  switch ([_manager state]) {

    case CBManagerStateUnknown:
      NSLog(@"BLEScan: Unknown state");
      break;
    case CBManagerStateResetting:
      NSLog(@"BLEScan: Resetting");
      break;
    case CBManagerStateUnsupported:
      NSLog(@"BLEScan: BLE unsupported");
      break;
    case CBManagerStateUnauthorized:
      NSLog(@"BLEScan: App is not authorized to use BLE");
      break;
    case CBManagerStatePoweredOff:
      NSLog(@"BLEScan: BLE is powered off");
      break;
    case CBManagerStatePoweredOn:
      NSLog(@"BLEScan: Powered on");
      [_manager scanForPeripheralsWithServices:nil options:nil];
      break;
  }
}

- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI {
     
    NSLog(@"Discovered %@ at %@", peripheral.name, RSSI);
}

@end


//#import "BLEScan.h"
//@import MultiplatformBleAdapter;
//
//@interface BLEScan () <BleClientManagerDelegate>
//@property(nonatomic) BleClientManager* manager;
//@property dispatch_queue_t methodQueue;
//@end
//
//@implementation BLEScan
//{
//    bool hasListeners;
//}
//
//@synthesize methodQueue = _methodQueue;
//
//- (void)dispatchEvent:(NSString * _Nonnull)name value:(id _Nonnull)value {
////  if (hasListeners) {
////          [self sendEventWithName:name body:value];
////  }
//  NSLog(@"event: %@ :: %@", name, value);
//
//  if([name  isEqual: @"StateChangeEvent"] && [value  isEqual: @"PoweredOn"]) {
//    NSDictionary* options = @{ @"allowDuplicates": @true };
//    [self startDeviceScan:nil options:options];
//  }
//}
//
//- (void)createClient: (NSString *) restoreIdentifierKey{
//  _manager = [BleAdapterFactory getNewAdapterWithQueue:self.methodQueue
//                                    restoreIdentifierKey:restoreIdentifierKey];
//  _manager.delegate = self;
//}
//
//
//- (void) startDeviceScan:(NSArray*)filteredUUIDs
//                 options:(NSDictionary*)options {
//  [_manager startDeviceScan:filteredUUIDs options:options];
//}
//
//- (void) stopDeviceScan {
//  [_manager stopDeviceScan];
//}
//
//@end
//

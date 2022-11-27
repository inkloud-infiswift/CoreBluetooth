//
//  BLEScan.m
//  PulseApp
//
//  Created by Rishu Agrawal on 19/11/22.
//

#import <Foundation/Foundation.h>
#import "BLEScan.h"
#import "AppDelegate.h"
#import "TESTBLE-Swift.h"

@class NSString;

@interface BLEScan() <CBCentralManagerDelegate, CLLocationManagerDelegate> {
  AppDelegate *appDelegate;
  NSManagedObjectContext *context;
  NSArray *dictionaries;
}

@property (strong, nonatomic) CBCentralManager * _Nonnull centralManager;
@property (strong, nonatomic) CLLocationManager * _Nonnull locationManager;
@property (strong) NSMutableDictionary<NSString*, CBPeripheral* > *  _Nullable discoveredPeripherals;

@end


static NSString* RestoreIdentifier = @"PulseAppBLEIdentifier";
@implementation BLEScan

@synthesize centralManager = _centralManager;
@synthesize locationManager = _locationManager;
@synthesize discoveredPeripherals = _discoveredPeripherals;

#pragma mark Singleton Methods

+ (id) sharedManager {
  NSLog(@"BLEScan: sharedManager called");
  static BLEScan *sharedMyManager = nil;
  static dispatch_once_t onceToken;
  
  dispatch_once(&onceToken, ^{
    sharedMyManager = [[self alloc] init];
  });
  
  return sharedMyManager;
}


#pragma mark initializers

- (id) init {
  NSLog(@"BLEScan: init");
  
  if (self = [super init]) {
    // init CoreBluetooth central manager
    [self initCBCentralManager];
    
    // initialize location manager
    [self initLocationManager];
    
    _discoveredPeripherals = [[NSMutableDictionary alloc] init];
    
    appDelegate = (AppDelegate *)[[UIApplication sharedApplication]delegate];
    context = appDelegate.persistentContainer.viewContext;
  }
  
  return self;
}

- (void) initCBCentralManager {
  _centralManager = [[CBCentralManager alloc] initWithDelegate:self
                                                         queue:dispatch_get_main_queue()
                                                       options:@{ CBCentralManagerOptionRestoreIdentifierKey:RestoreIdentifier }];
}

- (void) initLocationManager {
  _locationManager = [CLLocationManager alloc];
  _locationManager.delegate = self;
  
//  [_locationManager requestAlwaysAuthorization];
//  [_locationManager startUpdatingLocation];
}



#pragma mark CBCentralManagerDelegate

- (void) centralManagerDidUpdateState:(CBCentralManager *)central {
  NSLog(@"BLEScan: centralManagerDidUpdateState ");
  [self beginSearch];
}

- (void) beginSearch  {
  switch ([_centralManager state]) {

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
      CBUUID *id2 = [CBUUID UUIDWithString:@"00002080-0000-1000-8000-00805f9b34fb" ];
      NSArray *ids = @[ id2];
      
      [self startDeviceScan:ids options:nil];
      [self stopDeviceScanAfter:5.0];
      break;
  }
}

- (void) centralManager:(CBCentralManager *)central
  didDiscoverPeripheral:(CBPeripheral *)peripheral
      advertisementData:(NSDictionary<NSString *,id> *)advertisementData
                   RSSI:(NSNumber *)RSSI {
  NSLog(@"BLEScan: Peripheral discovered");
  
  [_discoveredPeripherals setObject:peripheral forKey:peripheral.name];
//  _discoveredPeripherals[peripheral.name] = peripheral;
  NSString* uuid = [self getServiceUUIDFromAdvertisementData:advertisementData];
  NSLog(@"BLEScan: Name = %@, UUID = %@", peripheral.name, uuid);
  
  // Save discoverd device to CoreData
//  NSManagedObject *entityObj = [NSEntityDescription insertNewObjectForEntityForName:@"Beacons" inManagedObjectContext:context];
//  [entityObj setValue:peripheral.identifier forKey:@"identifier"];
//  [entityObj setValue:peripheral.name forKey:@"name"];
//  [entityObj setValue:uuid forKey:@"serviceUUID"];
  
//  [appDelegate saveContext];
}

- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral*)peripheral {
  
  NSLog(@"BLEScan: Peripheral connected %@", peripheral.name);
}

- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {
  NSLog(@"BLEScan: failed to connect with error: %@", error);
}

- (void)centralManager:(CBCentralManager *)central willRestoreState:(NSDictionary<NSString *,id> *)dict {
  NSLog(@"BLEScan: willRestoreState - %@", dict);
}

#pragma mark CLLocationManagerDelegate

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray<CLLocation *> *)locations {
  NSLog(@"BLEScan: %@", locations.lastObject);
}



#pragma mark Class methods

/**
 * Start scanning for BLE devices with ServiceUUIDs
 */
- (void) startDeviceScan: (nullable NSArray<CBUUID *> *)serviceUUIDs
                 options:(nullable NSDictionary<NSString *, id> *)options {
  if (_centralManager.state == CBManagerStatePoweredOn) {
    NSLog(@"BLEScan: starting device scan");
    [_centralManager scanForPeripheralsWithServices:serviceUUIDs options:options];
    
    [self stopDeviceScanAfter:5.0];
  }
}

/**
 * Stop scanning of BLE devices after given interval
 */
- (void) stopDeviceScanAfter: (NSTimeInterval) interval {
  [NSTimer scheduledTimerWithTimeInterval:interval
                                   target:self
                                 selector:@selector(stopDeviceScan:)
                                 userInfo:nil
                                  repeats:NO];
}

/**
 * Stop scanning of iBecaons
 */
- (void) stopDeviceScan: (NSTimer *)timer {
  NSLog(@"BLEScan: stopping device scan: %@", _discoveredPeripherals);
  
  [_centralManager stopScan];
  
  for(NSString *name in _discoveredPeripherals) {
    CBPeripheral *peripheral = [_discoveredPeripherals objectForKey:name];
    
    NSLog(@"BLEScan: PeriName: %@", peripheral);
    
    [_centralManager connectPeripheral:peripheral options:nil];
  }
  
//  [self getConnectedPeripherals:<#(NSArray<CBUUID *> * _Nonnull)#>];
}

/**
 * Parses advertisementData from iBeacon discovery and returns Service UUID string
 */
- (NSString* ) getServiceUUIDFromAdvertisementData: (NSDictionary *)advertisementData {
  NSString* uuidString;
  NSDictionary* kCBAdvDataServiceData = advertisementData[@"kCBAdvDataServiceData"];
  
  // In iBeacon, we get ServiceUUID as keys and we're interested in the first ServiceUUID
  NSArray *keys = [kCBAdvDataServiceData allKeys];
  CBUUID* uuid = (CBUUID *)[keys objectAtIndex: 0];
  
  // converting CBUUID advertised by iBeacon to full UUID string based on logic from MultiplayformBLEAdaptor [link: https://github.com/dotintent/MultiPlatformBleAdapter/blob/master/iOS/classes/BleUtils.swift]
  uuidString = uuid.fullUUIDString;
  
  return uuidString;
}

- (void) getConnectedPeripherals: (NSArray<CBUUID *> *)serviceUUIDs  {
  NSLog(@"BLEScan: Scanning connected peripherals");
  
  NSLog(@"BLEScan: Scanning: %i", [_centralManager isScanning]);
  
  NSArray<CBPeripheral *> *peripherals = [_centralManager retrieveConnectedPeripheralsWithServices:serviceUUIDs];
  
  for (CBPeripheral* peripheral in peripherals) {
    NSLog(@"BLEScan: found connected peripheral - %@", peripheral.name);
  }
}

- (void) reconnectPeripheral: (CBPeripheral *) peripheral {
  [_centralManager cancelPeripheralConnection:peripheral];
  [_centralManager connectPeripheral:peripheral options:nil];
}

- (void) fetchDevicesFromCoreData {
  NSFetchRequest *requestExamLocation = [NSFetchRequest fetchRequestWithEntityName:@"Beacons"];
  NSArray *results = [context executeFetchRequest:requestExamLocation error:nil];
}

@end

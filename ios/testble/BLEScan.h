//
//  BLEScan.h
//  PulseApp
//
//  Created by Rishu Agrawal on 19/11/22.
//

#ifndef BLEScan_h
#define BLEScan_h
#import<CoreBluetooth/CoreBluetooth.h>

@interface BLEScan: NSObject

-(instancetype) initModule;

//-(void) createClient: (NSString *) restoreIdentifierKey;
//-(void) startDeviceScan:(NSArray*)filteredUUIDs
//                options:(NSDictionary*)options;
//-(void) stopDeviceScan;

@end

#endif /* BLEScan_h */

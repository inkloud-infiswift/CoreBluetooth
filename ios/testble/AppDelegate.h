#import <React/RCTBridgeDelegate.h>
#import <UIKit/UIKit.h>
#import<CoreBluetooth/CoreBluetooth.h>

@interface AppDelegate : UIResponder <UIApplicationDelegate, RCTBridgeDelegate>

@property (nonatomic, strong) UIWindow *window;
@property (strong, nonatomic) CBCentralManager *manager;

@end

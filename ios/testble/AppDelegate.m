#import "AppDelegate.h"

#import <React/RCTBridge.h>
#import <React/RCTBundleURLProvider.h>
#import <React/RCTRootView.h>
#import <GoogleMaps/GoogleMaps.h>
#import <AppCenterReactNative.h>
#import <AppCenterReactNativeAnalytics.h>
#import <AppCenterReactNativeCrashes.h>
#import <BackgroundTasks/BackgroundTasks.h>
#include "BLEScan.h"

#import "TESTBLE-Swift.h"

#ifdef FB_SONARKIT_ENABLED
#import <FlipperKit/FlipperClient.h>
#import <FlipperKitLayoutPlugin/FlipperKitLayoutPlugin.h>
#import <FlipperKitUserDefaultsPlugin/FKUserDefaultsPlugin.h>
#import <FlipperKitNetworkPlugin/FlipperKitNetworkPlugin.h>
#import <SKIOSNetworkPlugin/SKIOSNetworkAdapter.h>
#import <FlipperKitReactPlugin/FlipperKitReactPlugin.h>

static void InitializeFlipper(UIApplication *application) {
  FlipperClient *client = [FlipperClient sharedClient];
  SKDescriptorMapper *layoutDescriptorMapper = [[SKDescriptorMapper alloc] initWithDefaults];
  [client addPlugin:[[FlipperKitLayoutPlugin alloc] initWithRootNode:application withDescriptorMapper:layoutDescriptorMapper]];
  [client addPlugin:[[FKUserDefaultsPlugin alloc] initWithSuiteName:nil]];
  [client addPlugin:[FlipperKitReactPlugin new]];
  [client addPlugin:[[FlipperKitNetworkPlugin alloc] initWithNetworkAdapter:[SKIOSNetworkAdapter new]]];
  [client start];
}
#endif

static NSString* TaskID = @"tech.infiswift.PulseApp.BLEScan";

@implementation AppDelegate

- (void)applicationDidEnterBackground:(UIApplication *)application {
  NSLog(@"BLEScan: Background mode");
  [self taskScheduler];
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
#if DEBUG
  NSLog(@"Not using AppCenter");
#else
  [AppCenterReactNative register];
  [AppCenterReactNativeAnalytics registerWithInitiallyEnabled:true];
  [AppCenterReactNativeCrashes registerWithAutomaticProcessing];
#endif

#ifdef FB_SONARKIT_ENABLED
  InitializeFlipper(application);
#endif

  RCTBridge *bridge = [[RCTBridge alloc] initWithDelegate:self launchOptions:launchOptions];
  RCTRootView *rootView = [[RCTRootView alloc] initWithBridge:bridge
                                                   moduleName:@"PulseApp"
                                            initialProperties:nil];

  if (@available(iOS 13.0, *)) {
      rootView.backgroundColor = [UIColor systemBackgroundColor];
  } else {
      rootView.backgroundColor = [UIColor whiteColor];
  }

  self.window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
  UIViewController *rootViewController = [UIViewController new];
  rootViewController.view = rootView;
  self.window.rootViewController = rootViewController;
  [self.window makeKeyAndVisible];
  
  [BLEScan.sharedManager startDeviceScan:nil options:nil];
  
  [self configureTask];
  
  return YES;
}

-(void)configureTask{
    [[BGTaskScheduler sharedScheduler] registerForTaskWithIdentifier:TaskID
                                                          usingQueue:nil
                                                       launchHandler:^(BGTask *task) {
        [self handleAppRefreshTask:task];
    }];
}

-(void)handleAppRefreshTask:(__kindof BGTask *)task  {
  NSLog(@"BLEScan: Executing task: %@", TaskID);
  
  CBUUID *id2 = [CBUUID UUIDWithString:@"00002080-0000-1000-8000-00805f9b34fb" ];
  NSArray *ids = @[id2];
  
  [BLEScan.sharedManager getConnectedPeripherals:ids];
  
  // wait for 15 seconds before marking current task as complete and rescheduling it again
  [self waitForTaskBeforeReschedule:6.0 task:task];
}
- (void)waitForTaskBeforeReschedule: (NSTimeInterval) interval
                                task: (__kindof BGTask *)task {
    [NSTimer scheduledTimerWithTimeInterval:interval
                                     target:self
                                   selector:@selector(scheduleTaskAfterInterval:)
                                   userInfo:task
                                    repeats:NO];
}

- (void)scheduleTaskAfterInterval: (NSTimer *)timer {
  // Complete previous task
//  BGTask* task = [timer userInfo];
//  [task setTaskCompletedWithSuccess:true];
  
  // Schedule fresh task
  [self taskScheduler];
}

- (void)taskScheduler {
  NSLog(@"BLEScan: Scheduling background task: %@", TaskID);
  
  BGProcessingTaskRequest *request = [[BGProcessingTaskRequest alloc] initWithIdentifier:TaskID];
  request.earliestBeginDate = [NSDate dateWithTimeIntervalSinceNow:2*60];
  NSError *error = NULL;
  
  BOOL success = [[BGTaskScheduler sharedScheduler] submitTaskRequest:request error:&error];
  if (!success) {
      NSLog(@"BLEScan: Failed to submit request: %@",error);
  }
  
}

- (NSURL *)sourceURLForBridge:(RCTBridge *)bridge
{
#if DEBUG
  return [[RCTBundleURLProvider sharedSettings] jsBundleURLForBundleRoot:@"index" fallbackResource:nil];
#else
  return [[NSBundle mainBundle] URLForResource:@"main" withExtension:@"jsbundle"];
#endif
}


#pragma mark - Core Data stack

@synthesize persistentContainer = _persistentContainer;

- (NSPersistentContainer *)persistentContainer {
    // The persistent container for the application. This implementation creates and returns a container, having loaded the store for the application to it.
    @synchronized (self) {
        if (_persistentContainer == nil) {
            _persistentContainer = [[NSPersistentContainer alloc] initWithName:@"CoreDataModel"];
            [_persistentContainer loadPersistentStoresWithCompletionHandler:^(NSPersistentStoreDescription *storeDescription, NSError *error) {
                if (error != nil) {
                    // Replace this implementation with code to handle the error appropriately.
                    // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                    
                    /*
                     Typical reasons for an error here include:
                     * The parent directory does not exist, cannot be created, or disallows writing.
                     * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                     * The device is out of space.
                     * The store could not be migrated to the current model version.
                     Check the error message to determine what the actual problem was.
                     */
                    NSLog(@"Unresolved error %@, %@", error, error.userInfo);
                    abort();
                }
            }];
        }
    }
    return _persistentContainer;
}

#pragma mark - Core Data Saving support

- (void)saveContext {
    NSManagedObjectContext *context = self.persistentContainer.viewContext;
    NSError *error = nil;
    if ([context hasChanges] && ![context save:&error]) {
        // Replace this implementation with code to handle the error appropriately.
        // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
        NSLog(@"Unresolved error %@, %@", error, error.userInfo);
        abort();
    }
}

@end

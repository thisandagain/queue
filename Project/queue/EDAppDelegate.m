//
//  EDAppDelegate.m
//  queue
//
//  Created by Andrew Sliwinski on 6/29/12.
//  Copyright (c) 2012 Andrew Sliwinski. All rights reserved.
//

#import "EDAppDelegate.h"
#import "EDViewController.h"
#import "EDQueueStorageEngine.h"

@implementation EDAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    EDQueueStorageEngine *fmdbBasedStorage = [[EDQueueStorageEngine alloc] initWithName:@"database.sample.sqlite"];

    self.persistentTaskQueue = [[EDQueue alloc] initWithPersistentStore:fmdbBasedStorage];

    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    
    self.viewController = [[EDViewController alloc] initWithNibName:@"EDViewController" bundle:nil];

    self.viewController.persistentTaskQueue = self.persistentTaskQueue;

    self.window.rootViewController = self.viewController;
    [self.window makeKeyAndVisible];
    return YES;
}

//

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    [self.persistentTaskQueue setDelegate:self];
    [self.persistentTaskQueue start];
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    [self.persistentTaskQueue stop];
}

- (void)queue:(EDQueue *)queue processJob:(EDQueueJob *)job completion:(void (^)(EDQueueResult))block
{
    sleep(1);
    
    @try {
        if ([job.task isEqualToString:@"success"]) {
            block(EDQueueResultSuccess);
        } else if ([job.task isEqualToString:@"fail"]) {
            block(EDQueueResultFail);
        } else {
            block(EDQueueResultCritical);
        }
    }
    @catch (NSException *exception) {
        block(EDQueueResultCritical);
    }
}
- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end

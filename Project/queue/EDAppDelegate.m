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
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    
    self.viewController = [[EDViewController alloc] initWithNibName:@"EDViewController" bundle:nil];
    self.window.rootViewController = self.viewController;
    [self.window makeKeyAndVisible];
    return YES;
}

//

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    [[EDQueue defaultQueue] setDelegate:self];
    [[EDQueue defaultQueue] start];
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    [[EDQueue defaultQueue] stop];
}

- (void)queue:(EDQueue *)queue processJob:(EDQueueJob *)job completion:(void (^)(EDQueueResult))block
{
    sleep(1);
    
    @try {
        if ([job.tag isEqualToString:@"success"]) {
            block(EDQueueResultSuccess);
        } else if ([job.tag isEqualToString:@"fail"]) {
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

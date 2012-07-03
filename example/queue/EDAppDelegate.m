//
//  EDAppDelegate.m
//  queue
//
//  Created by Andrew Sliwinski on 6/29/12.
//  Copyright (c) 2012 DIY, Co. All rights reserved.
//

#import "EDAppDelegate.h"
#import "EDViewController.h"

@implementation EDAppDelegate

@synthesize window = _window;
@synthesize viewController = _viewController;

- (void)dealloc
{
    [_window release];
    [_viewController release];
    [super dealloc];
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]] autorelease];
    
    //
        
    [[EDQueue sharedInstance] setDelegate:self];
    [[EDQueue sharedInstance] start];
    
    //
    
    self.viewController = [[[EDViewController alloc] initWithNibName:@"EDViewController" bundle:nil] autorelease];
    self.window.rootViewController = self.viewController;
    [self.window makeKeyAndVisible];
    return YES;
}

- (EDQueueResult)queue:(EDQueue *)queue processJob:(NSDictionary *)job
{
    sleep(1);
    
    if ([[job objectForKey:@"task"] isEqualToString:@"success"]) {
        return kEDQueueResultSuccess;
    } else if ([[job objectForKey:@"task"] isEqualToString:@"fail"]) {
        return kEDQueueResultFail;
    }
    
    return kEDQueueResultCritical;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    [[EDQueue sharedInstance] stop];
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

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end

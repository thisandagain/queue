//
//  AppDelegate.m
//  macqueue
//
//  Created by Aaron Taylor on 5/21/15.
//  Copyright (c) 2015 Aaron Taylor. All rights reserved.
//

#import "AppDelegate.h"

@interface AppDelegate ()

@end

@implementation AppDelegate

- (void)queue:(EDQueue *)queue processJob:(NSDictionary *)job completion:(void (^)(EDQueueResult))block
{
    sleep(1);
    
    @try {
        if ([[job objectForKey:@"task"] isEqualToString:@"success"]) {
            block(EDQueueResultSuccess);
        } else if ([[job objectForKey:@"task"] isEqualToString:@"fail"]) {
            block(EDQueueResultFail);
        } else {
            block(EDQueueResultCritical);
        }
    }
    @catch (NSException *exception) {
        block(EDQueueResultCritical);
    }
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    // Insert code here to initialize your application    
    
    [[EDQueue sharedInstance] setDelegate:self];
    [[EDQueue sharedInstance] start];
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
    [[EDQueue sharedInstance] stop];
}

@end

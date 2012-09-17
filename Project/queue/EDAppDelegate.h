//
//  EDAppDelegate.h
//  queue
//
//  Created by Andrew Sliwinski on 6/29/12.
//  Copyright (c) 2012 Andrew Sliwinski. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "EDQueue.h"

@class EDViewController;

@interface EDAppDelegate : UIResponder <UIApplicationDelegate, EDQueueDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) EDViewController *viewController;

@end
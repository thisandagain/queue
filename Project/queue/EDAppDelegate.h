//
//  EDAppDelegate.h
//  queue
//
//  Created by Andrew Sliwinski on 6/29/12.
//  Copyright (c) 2012 Andrew Sliwinski. All rights reserved.
//

@import UIKit;

#import "EDQueue.h"

@class EDViewController;

@interface EDAppDelegate : UIResponder <UIApplicationDelegate, EDQueueDelegate>

@property (nonatomic) UIWindow *window;
@property (nonatomic) EDViewController *viewController;

@end
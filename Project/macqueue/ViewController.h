//
//  ViewController.h
//  macqueue
//
//  Created by Aaron Taylor on 5/21/15.
//  Copyright (c) 2015 Aaron Taylor. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "EDQueue.h"

@interface ViewController : NSViewController

@property (nonatomic, retain) IBOutlet NSTextView *activity;

- (IBAction)addSuccess:(id)sender;
- (IBAction)addFail:(id)sender;
- (IBAction)addCritical:(id)sender;

@end


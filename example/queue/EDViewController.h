//
//  EDViewController.h
//  queue
//
//  Created by Andrew Sliwinski on 6/29/12.
//  Copyright (c) 2012 Andrew Sliwinski. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "EDQueue.h"

@interface EDViewController : UIViewController

@property (nonatomic, retain) IBOutlet UITextView *activity;

- (IBAction)addSuccess:(id)sender;
- (IBAction)addFail:(id)sender;
- (IBAction)addCritical:(id)sender;

@end
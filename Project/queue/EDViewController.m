//
//  EDViewController.m
//  queue
//
//  Created by Andrew Sliwinski on 6/29/12.
//  Copyright (c) 2012 Andrew Sliwinski. All rights reserved.
//

#import "EDViewController.h"

#pragma mark - View lifecycle

@implementation EDViewController

@synthesize activity = _activity;

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Register notifications
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc addObserver:self selector:@selector(receivedNotification:) name:@"EDQueueJobDidSucceed" object:nil];
    [nc addObserver:self selector:@selector(receivedNotification:) name:@"EDQueueJobDidFail" object:nil];
    [nc addObserver:self selector:@selector(receivedNotification:) name:@"EDQueueDidStart" object:nil];
    [nc addObserver:self selector:@selector(receivedNotification:) name:@"EDQueueDidStop" object:nil];
    [nc addObserver:self selector:@selector(receivedNotification:) name:@"EDQueueDidDrain" object:nil];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - UI events

- (IBAction)addSuccess:(id)sender
{
    [[EDQueue sharedInstance] enqueueWithData:@{ @"nyan" : @"cat" } forTask:@"success"];
}

- (IBAction)addFail:(id)sender
{
    [[EDQueue sharedInstance] enqueueWithData:nil forTask:@"fail"];
}

- (IBAction)addCritical:(id)sender
{
    [[EDQueue sharedInstance] enqueueWithData:nil forTask:@"critical"];
}
     
#pragma mark - Notifications
     
- (void)receivedNotification:(NSNotification *)notification
{
    self.activity.text = [NSString stringWithFormat:@"%@%@\n", self.activity.text, notification];
    [self.activity scrollRangeToVisible:NSMakeRange([self.activity.text length], 0)];
}

#pragma mark - Dealloc

- (void)releaseObjects
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    _activity = nil;
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    [self releaseObjects];
}

- (void)dealloc
{
    [self releaseObjects];
}

@end

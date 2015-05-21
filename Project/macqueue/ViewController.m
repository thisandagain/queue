//
//  ViewController.m
//  macqueue
//
//  Created by Aaron Taylor on 5/21/15.
//  Copyright (c) 2015 Aaron Taylor. All rights reserved.
//

#import "ViewController.h"

@implementation ViewController

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

- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];
    
    // Update the view, if already loaded.
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
    dispatch_async(dispatch_get_main_queue(), ^{
        NSString* str = [NSString stringWithFormat:@"%@\n", notification];
        NSAttributedString* attr = [[NSAttributedString alloc] initWithString: str];
        
        [[self.activity textStorage] appendAttributedString:attr];
        [self.activity scrollRangeToVisible:NSMakeRange([[self.activity string] length], 0)];
    });
}

#pragma mark - Dealloc

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    _activity = nil;
}

@end

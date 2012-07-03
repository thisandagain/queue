//
//  EDViewController.m
//  queue
//
//  Created by Andrew Sliwinski on 6/29/12.
//  Copyright (c) 2012 DIY, Co. All rights reserved.
//

#import "EDViewController.h"

#pragma mark - View lifecycle

@implementation EDViewController

@synthesize activity = _activity;

- (void)viewDidLoad
{
    [super viewDidLoad];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - UI events

- (IBAction)addSuccess:(id)sender
{
    [[EDQueue sharedInstance] enqueueWithData:nil forTask:@"success"];
}

- (IBAction)addFail:(id)sender
{
    [[EDQueue sharedInstance] enqueueWithData:nil forTask:@"fail"];
}

- (IBAction)addCritical:(id)sender
{
    [[EDQueue sharedInstance] enqueueWithData:nil forTask:@"critical"];
}

#pragma mark - Dealloc

- (void)releaseObjects
{
    [_activity release]; _activity = nil;
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    [self releaseObjects];
}

- (void)dealloc
{
    [self releaseObjects];
    [super dealloc];
}

@end

//
//  EDQueue.m
//  queue
//
//  Created by Andrew Sliwinski on 6/29/12.
//  Copyright (c) 2012 DIY, Co. All rights reserved.
//

#import "EDQueue.h"

//

@interface EDQueue ()
@property (nonatomic, retain) NSMutableArray *queue;
@property (nonatomic, retain) NSTimer *timer;
@property (nonatomic, assign) NSUInteger active;
@end

//

@implementation EDQueue

@synthesize delegate = _delegate;
@synthesize concurrencyLimit = _concurrencyLimit;
@synthesize statusInterval = _statusInterval;
@synthesize retryFailureImmediately = _retryFailureImmediately;
@synthesize retryLimit = _retryLimit;
@synthesize queue = _queue;
@synthesize timer = _timer;
@synthesize active = _active;

#pragma mark - Init

+ (EDQueue *)sharedInstance
{
    DEFINE_SHARED_INSTANCE_USING_BLOCK(^{
        return [[self alloc] init];
    });
}

- (id)init
{
    self = [super init];
    if (self)
    {
        _concurrencyLimit           = 2;
        _statusInterval             = 0.03f;
        _retryFailureImmediately    = true;
        _retryLimit                 = 4;
        
        _queue                      = [[NSMutableArray alloc] init];
        _timer                      = [[NSTimer alloc] init];
        _active                     = 0;
    }
    return self;
}

#pragma mark - Public methods

/**
 * Adds a new job to the queue.
 *
 * @param {id} Data
 * @param {NSString} Task label
 *
 * @return {void}
 */
- (void)enqueueWithData:(id)data forTask:(NSString *)task
{
    [self.queue addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:
                                [NSNumber numberWithInt:0], @"attempt",
                                task, @"task",
                                data, @"data",
                                nil]];
}

/**
 * Starts the queue.
 *
 * @return {void}
 */
- (void)start
{
    self.timer = [NSTimer scheduledTimerWithTimeInterval:self.statusInterval target:self selector:@selector(tick) userInfo:nil repeats:true];
}

/**
 * Stops the queue.
 *
 * @return {void}
 */
- (void)stop
{
    [self.timer invalidate];
    self.timer = nil;
}

#pragma mark - Status loop

- (void)tick
{
    dispatch_queue_t gcd = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0);
    dispatch_async(gcd, ^{
        
        if ([self.queue count] != 0 && active < self.concurrencyLimit) {
            // Fetch job
            id job = [self.queue objectAtIndex:0];
            if (job != nil) {
                [[job retain] autorelease];
                [self.queue removeObjectAtIndex:0];
                active++;
            }
            
            // Pass job to delegate
            EDQueueResult result = [self.delegate queue:self processJob:job];
            active--;
            
            // Check result
            switch (result) {
                case kEDQueueResultSuccess:
                    NSLog(@"Win!!!!");
                    break;
                case kEDQueueResultFail:
                    NSLog(@"FAIL!!!");
                    NSUInteger currentAttempt = [[job objectForKey:@"attempt"] intValue] + 1;
                    if (currentAttempt < self.retryLimit)
                    {
                        [job setValue:[NSNumber numberWithInt:currentAttempt] forKey:@"attempt"];
                        (self.retryFailureImmediately) ? [self.queue insertObject:job atIndex:0] : [self.queue addObject:job];
                    }
                    break;
                case kEDQueueResultCritical:
                    [self errorWithMessage:@"Critical error. Stopping queue..."];
                    [self stop];
                    break;
            }
        }
        
    });
}

#pragma mark - Private methods

- (void)errorWithMessage:(NSString *)message
{
    NSLog(@"EDQueue Error: %@", message);
}

#pragma mark - Dealloc

- (void)dealloc
{    
    self.delegate = nil;
    
    [_queue release]; _queue = nil;
    [_timer release]; _timer = nil;
    
    [super dealloc];
}

@end

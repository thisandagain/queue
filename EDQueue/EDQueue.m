//
//  EDQueue.m
//  queue
//
//  Created by Andrew Sliwinski on 6/29/12.
//  Copyright (c) 2012 Andrew Sliwinski. All rights reserved.
//

#import "EDQueue.h"
#import "EDQueueStorageEngine.h"

NSString *const EDQueueDidStart = @"EDQueueDidStart";
NSString *const EDQueueDidStop = @"EDQueueDidStop";
NSString *const EDQueueJobDidSucceed = @"EDQueueJobDidSucceed";
NSString *const EDQueueJobDidFail = @"EDQueueJobDidFail";
NSString *const EDQueueDidDrain = @"EDQueueDidDrain";

NSString *const EDQueueNameKey = @"name";
NSString *const EDQueueDataKey = @"data";

NS_ASSUME_NONNULL_BEGIN

@interface EDQueue ()
{
    BOOL _isRunning;
    BOOL _isActive;
    NSUInteger _retryLimit;
}

@property (nonatomic) EDQueueStorageEngine *engine;
@property (nonatomic, readwrite, nullable) NSString *activeTask;

@end

//

@implementation EDQueue

@synthesize isRunning = _isRunning;
@synthesize isActive = _isActive;
@synthesize retryLimit = _retryLimit;

#pragma mark - Singleton

+ (EDQueue *)sharedInstance
{
    static EDQueue *singleton = nil;
    static dispatch_once_t once = 0;
    dispatch_once(&once, ^{
        singleton = [[self alloc] init];
    });
    return singleton;
}

#pragma mark - Init

- (id)init
{
    self = [super init];
    if (self) {
        _engine     = [[EDQueueStorageEngine alloc] init];
        _retryLimit = 4;
    }
    return self;
}

- (void)dealloc
{    
    self.delegate = nil;
    _engine = nil;
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
- (void)enqueueWithData:(nullable NSDictionary *)data forTask:(NSString *)task
{
    if (data == nil) data = @{};
    [self.engine createJob:data forTask:task];
    [self tick];
}

/**
 * Returns true if a job exists for this task.
 *
 * @param {NSString} Task label
 *
 * @return {Boolean}
 */
- (BOOL)jobExistsForTask:(NSString *)task
{
    BOOL jobExists = [self.engine jobExistsForTask:task];
    return jobExists;
}

/**
 * Returns true if the active job if for this task.
 *
 * @param {NSString} Task label
 *
 * @return {Boolean}
 */
- (BOOL)jobIsActiveForTask:(NSString *)task
{
    BOOL jobIsActive = [self.activeTask length] > 0 && [self.activeTask isEqualToString:task];
    return jobIsActive;
}

/**
 * Returns the list of jobs for this 
 *
 * @param {NSString} Task label
 *
 * @return {NSArray}
 */
- (NSDictionary *)nextJobForTask:(NSString *)task
{
    NSDictionary *nextJobForTask = [self.engine fetchJobForTask:task];
    return nextJobForTask;
}

/**
 * Starts the queue.
 *
 * @return {void}
 */
- (void)start
{
    if (!self.isRunning) {
        _isRunning = YES;
        [self tick];

        NSDictionary *object = @{ EDQueueNameKey : EDQueueDidStart };

//        [self performSelectorOnMainThread:@selector(postNotificationOnMainThread:) withObject:object waitUntilDone:NO];
        [self postNotificationOnMainThread:object];
    }
}

/**
 * Stops the queue.
 * @note Jobs that have already started will continue to process even after stop has been called.
 *
 * @return {void}
 */
- (void)stop
{
    if (self.isRunning) {
        _isRunning = NO;

        NSDictionary *object = @{ EDQueueNameKey : EDQueueDidStop };

//        [self performSelectorOnMainThread:@selector(postNotification:) withObject:object waitUntilDone:NO];
        [self postNotificationOnMainThread:object];
    }
}



/**
 * Empties the queue.
 * @note Jobs that have already started will continue to process even after empty has been called.
 *
 * @return {void}
 */
- (void)empty
{
    [self.engine removeAllJobs];
}


#pragma mark - Private methods

/**
 * Checks the queue for available jobs, sends them to the processor delegate, and then handles the response.
 *
 * @return {void}
 */
- (void)tick
{
    dispatch_queue_t gcd = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0);
    dispatch_async(gcd, ^{
        if (self.isRunning && !self.isActive && [self.engine fetchJobCount] > 0) {
            // Start job
            _isActive = YES;
            NSDictionary *job = [self.engine fetchJob];
            self.activeTask = [job objectForKey:@"task"];
            
            // Pass job to delegate
            if ([self.delegate respondsToSelector:@selector(queue:processJob:completion:)]) {
                [self.delegate queue:self processJob:job completion:^(EDQueueResult result) {
                    [self processJob:job withResult:result];
                    self.activeTask = nil;
                }];
            } else {
                EDQueueResult result = [self.delegate queue:self processJob:job];
                [self processJob:job withResult:result];
                self.activeTask = nil;
            }
        }
    });
}

- (void)processJob:(NSDictionary*)job withResult:(EDQueueResult)result
{
    if (!job) {
        job = @{};
    }
    // Check result
    switch (result) {
        case EDQueueResultSuccess:

//            NSDictionary *object = @{
//                                     EDQueueNameKey : EDQueueJobDidSucceed,
//                                     EDQueueDataKey : job
//                                     };
            //[NSDictionary dictionaryWithObjectsAndKeys:EDQueueJobDidSucceed, EDQueueNameKey, job, EDQueueDataKey, nil]

//            [self performSelectorOnMainThread:@selector(postNotification:)
//                                   withObject:@{
//                                                EDQueueNameKey : EDQueueJobDidSucceed,
//                                                EDQueueDataKey : job
//                                                }
//                                waitUntilDone:false];

            [self postNotificationOnMainThread:@{
                                                 EDQueueNameKey : EDQueueJobDidSucceed,
                                                 EDQueueDataKey : job
                                                 }];

            [self.engine removeJob:[job objectForKey:@"id"]];
            break;

        case EDQueueResultFail:
//            [self performSelectorOnMainThread:@selector(postNotification:) withObject:[NSDictionary dictionaryWithObjectsAndKeys:EDQueueJobDidFail, EDQueueNameKey, job, EDQueueDataKey, nil] waitUntilDone:true];

            [self postNotificationOnMainThread:@{
                                                 EDQueueNameKey : EDQueueJobDidFail,
                                                 EDQueueDataKey : job
                                                 }];

            NSUInteger currentAttempt = [[job objectForKey:@"attempts"] intValue] + 1;

            if (currentAttempt < self.retryLimit) {
                [self.engine incrementAttemptForJob:[job objectForKey:@"id"]];
            } else {
                [self.engine removeJob:[job objectForKey:@"id"]];
            }
            break;
        case EDQueueResultCritical:

//            [self performSelectorOnMainThread:@selector(postNotification:) withObject:[NSDictionary dictionaryWithObjectsAndKeys:EDQueueJobDidFail, EDQueueNameKey, job, EDQueueDataKey, nil] waitUntilDone:false];

            [self postNotificationOnMainThread:@{
                                                 EDQueueNameKey : EDQueueJobDidFail,
                                                 EDQueueDataKey : job
                                                 }];

            [self errorWithMessage:@"Critical error. Job canceled."];
            [self.engine removeJob:[job objectForKey:@"id"]];
            break;
    }
    
    // Clean-up
    _isActive = NO;
    
    // Drain
    if ([self.engine fetchJobCount] == 0) {
//        [self performSelectorOnMainThread:@selector(postNotification:) withObject:[NSDictionary dictionaryWithObjectsAndKeys:EDQueueDidDrain, EDQueueNameKey, nil, EDQueueDataKey, nil] waitUntilDone:false];
        [self postNotificationOnMainThread:@{
                                             EDQueueNameKey : EDQueueDidDrain,
                                             }];
    } else {
        [self performSelectorOnMainThread:@selector(tick) withObject:nil waitUntilDone:false];
    }
}

/**
 * Posts a notification (used to keep notifications on the main thread).
 *
 * @param {NSDictionary} Object
 *                          - name: Notification name
 *                          - data: Data to be attached to notification
 *
 * @return {void}
 */
- (void)postNotificationOnMainThread:(NSDictionary *)object
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:[object objectForKey:EDQueueNameKey]
                                                            object:[object objectForKey:EDQueueDataKey]];
    });

}

/**
 * Writes an error message to the log.
 *
 * @param {NSString} Message
 *
 * @return {void}
 */
- (void)errorWithMessage:(NSString *)message
{
    NSLog(@"EDQueue Error: %@", message);
}

@end

NS_ASSUME_NONNULL_END

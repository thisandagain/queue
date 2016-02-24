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

static NSString *const EDQueueNameKey = @"name";
static NSString *const EDQueueDataKey = @"data";


NS_ASSUME_NONNULL_BEGIN

@interface EDQueue ()

@property (nonatomic, readwrite, nullable) NSString *activeJobTag;

@end


@implementation EDQueue

+ (instancetype)defaultQueue
{
    static EDQueue *defaultQueue;
    static dispatch_once_t onceToken;

    dispatch_once(&onceToken, ^{
        EDQueueStorageEngine *fmdbBasedStorage = [[EDQueueStorageEngine alloc] initWithName:@"edqueue.default.v7.3.sqlite"];

        defaultQueue = [[EDQueue alloc] initWithPersistentStore:fmdbBasedStorage];
    });

    return defaultQueue;
}

- (instancetype)initWithPersistentStore:(id<EDQueuePersistentStorage>)persistentStore
{
    self = [super init];
    if (self) {
        _retryLimit = 4;
        _storage = persistentStore;
    }
    return self;
}


#pragma mark - Public methods

/**
 * Adds a new job to the queue.
 *
 * @param {EDQueueJob} job
 *
 * @return {void}
 */
- (void)enqueueJob:(EDQueueJob *)job
{
    [self.storage createJob:job];
    [self tick];
}

/**
 * Returns true if a job exists for this tag.
 *
 * @param {NSString} job tag
 *
 * @return {Boolean}
 */
- (BOOL)jobExistsForTag:(NSString *)tag
{
    BOOL jobExists = [self.storage jobExistsForTag:tag];
    return jobExists;
}

/**
 * Returns true if the active job if for this tag.
 *
 * @param {NSString} job tag
 *
 * @return {Boolean}
 */
- (BOOL)jobIsActiveForTag:(NSString *)tag
{
    BOOL jobIsActive = [self.activeJobTag length] > 0 && [self.activeJobTag isEqualToString:tag];
    return jobIsActive;
}

/**
 * Returns the next job for tag
 *
 * @param {NSString} job tag
 *
 * @return {NSArray}
 */
- (nullable EDQueueJob *)nextJobForTag:(NSString *)tag
{
    id<EDQueueStorageItem> item = [self.storage fetchNextJobForTag:tag];
    return item.job;
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
    [self.storage removeAllJobs];
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
        if (self.isRunning && !self.isActive && [self.storage jobCount] > 0) {
            // Start job
            _isActive = YES;
            id<EDQueueStorageItem> storedJob = [self.storage fetchNextJob];
            self.activeJobTag = storedJob.job.tag;
            
            // Pass job to delegate
                [self.delegate queue:self processJob:storedJob.job completion:^(EDQueueResult result) {
                    [self processJob:storedJob withResult:result];
                    self.activeJobTag = nil;
                }];
        }
    });
}

- (void)processJob:(id<EDQueueStorageItem>)storedJob withResult:(EDQueueResult)result
{
    // Check result
    switch (result) {
        case EDQueueResultSuccess:

            [self postNotificationOnMainThread:@{
                                                 EDQueueNameKey : EDQueueJobDidSucceed,
                                                 EDQueueDataKey : storedJob.job
                                                 }];

            [self.storage removeJob:storedJob];
            break;

        case EDQueueResultFail:

            [self postNotificationOnMainThread:@{
                                                 EDQueueNameKey : EDQueueJobDidFail,
                                                 EDQueueDataKey : storedJob.job
                                                 }];

            NSUInteger currentAttempt = storedJob.attempts.integerValue + 1;

            if (currentAttempt < self.retryLimit) {
                [self.storage incrementAttemptForJob:storedJob];
            } else {
                [self.storage removeJob:storedJob];
            }
            break;
        case EDQueueResultCritical:

            [self postNotificationOnMainThread:@{
                                                 EDQueueNameKey : EDQueueJobDidFail,
                                                 EDQueueDataKey : storedJob.job
                                                 }];

            [self errorWithMessage:@"Critical error. Job canceled."];
            [self.storage removeJob:storedJob];
            break;
    }
    
    // Clean-up
    _isActive = NO;
    
    // Drain
    if ([self.storage jobCount] == 0) {

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

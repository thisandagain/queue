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

@property (nonatomic, nullable) NSString *activeJobTag;
@property (nonatomic) dispatch_queue_t dispatchQueue;

@end


@implementation EDQueue

+ (instancetype)defaultQueue
{
    static EDQueue *defaultQueue;
    static dispatch_once_t onceToken;

    dispatch_once(&onceToken, ^{
        EDQueueStorageEngine *fmdbBasedStorage = [[EDQueueStorageEngine alloc] initWithName:@"edqueue.default.v1.0.sqlite"];

        defaultQueue = [[EDQueue alloc] initWithPersistentStore:fmdbBasedStorage];
    });

    return defaultQueue;
}

- (instancetype)initWithPersistentStore:(id<EDQueuePersistentStorage>)persistentStore
{
    self = [super init];
    if (self) {
        _storage = persistentStore;
        self.dispatchQueue = dispatch_queue_create("edqueue.serial", DISPATCH_QUEUE_SERIAL);
    }
    return self;
}


#pragma mark - Public methods

/**
 * Total number of enqueued & valid jobs.
 *
 * @return {NSInteger}
 */
- (NSInteger)jobCount
{
    return [self.storage jobCount];
}

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
    id<EDQueueStorageItem> item = [self.storage fetchNextJobForTag:tag validForDate:[NSDate date]];
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

    [self postNotificationOnMainThread:@{ EDQueueNameKey : EDQueueDidDrain }];
}


#pragma mark - Private methods

/**
 * Checks the queue for available jobs, sends them to the processor delegate, and then handles the response.
 *
 * @return {void}
 */
- (void)tick
{
    dispatch_barrier_async(self.dispatchQueue, ^{

        if (!self.isRunning) {
            return;
        }

        if (self.isActive) {
            return;
        }

        if ([self.storage jobCount] > 0) {

            id<EDQueueStorageItem> storedJob = [self.storage fetchNextJobValidForDate:[NSDate date]];

            if (!storedJob) {
                __weak typeof(self) weakSelf = self;
                NSTimeInterval nextTime = [self.storage fetchNextJobTimeInterval];
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(nextTime * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [weakSelf performSelectorOnMainThread:@selector(tick) withObject:nil waitUntilDone:false];
                });

                return;
            }

            // Start job & Pass job to delegate
            self.activeJobTag = storedJob.job.tag;
            _isActive = YES;

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

            BOOL shouldRetry = NO;

            if (storedJob.job.maxRetryCount == EDQueueJobInfiniteRetryCount) {
                shouldRetry = YES;
            } else if(storedJob.job.maxRetryCount > storedJob.attempts.integerValue) {
                shouldRetry = YES;
            }

            if (shouldRetry) {
                [self.storage scheduleNextAttemptForJob:storedJob];
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

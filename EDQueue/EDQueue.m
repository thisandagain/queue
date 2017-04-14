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

@interface EDQueue () {
    BOOL _isRunning;
    NSUInteger _retryLimit;
}

@property (nonatomic) EDQueueStorageEngine *engine;
@property (nonatomic) BOOL isTicking;

@end


@implementation EDQueue

@synthesize isRunning = _isRunning;
@synthesize retryLimit = _retryLimit;

#pragma mark - Singleton

+ (EDQueue *)sharedInstance {
    static EDQueue *singleton = nil;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        singleton = [[self alloc] init];
    });
    
    return singleton;
}

#pragma mark - Init

- (id)init {
    self = [super init];
    if (self) {
        _engine     = [[EDQueueStorageEngine alloc] init];
        _retryLimit = 4;
    }
    
    return self;
}

- (void)dealloc {
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
- (void)enqueueWithData:(id)data forTask:(NSString *)task {
    if (data == nil) data = @{};
    [self.engine createJob:data forTask:task];
    [self tick];
}

/**
 * Starts the queue.
 *
 * @return {void}
 */
- (void)start {
    if (!self.isRunning) {
        _isRunning = YES;
        if (!self.processingJobs) {
            self.processingJobs = [@{} mutableCopy];
        }
        
        [self tick];
        
        [self performSelectorOnMainThread:@selector(postNotification:)
                               withObject:[NSDictionary dictionaryWithObjectsAndKeys:EDQueueDidStart, @"name", nil, @"data", nil]
                            waitUntilDone:false];
    }
}

/**
 * Stops the queue.
 * @note Jobs that have already started will continue to process even after stop has been called.
 *
 * @return {void}
 */
- (void)stop {
    if (self.isRunning) {
        _isRunning = NO;
        [self performSelectorOnMainThread:@selector(postNotification:)
                               withObject:[NSDictionary dictionaryWithObjectsAndKeys:EDQueueDidStop, @"name", nil, @"data", nil]
                            waitUntilDone:false];
    }
}



/**
 * Empties the queue.
 * @note Jobs that have already started will continue to process even after empty has been called.
 *
 * @return {void}
 */
- (void)empty {
    [self.engine removeAllJobs];
}

#pragma mark - Private methods

- (void)markJobProcessing:(id)job {
    NSString *taskName = job[@"task"];
    if (!self.processingJobs[taskName]) {
        self.processingJobs[taskName] = [@[] mutableCopy];
    }
    
    [self.processingJobs[taskName] addObject: job[@"id"]];
}

- (void)removeJobFromProcessing:(id)job {
    NSString *taskName = job[@"task"];
    if (self.processingJobs[taskName]) {
        [self.processingJobs[taskName] removeObject:job[@"id"]];
    }
}

- (NSArray *)processingJobsForQueue:(NSString *)queue {
    return self.processingJobs[queue];
}

- (BOOL)canProcessJobForQueue:(NSString *)queue {
    return [self maxConcurrentJobsPerQueue] >= [self numberOfProcessingJobsForQueue:queue];
}

- (int)numberOfProcessingJobsForQueue:(NSString *)queue {
    NSArray *processingJobsForQueue = self.processingJobs[queue];
    
    if (processingJobsForQueue) {
        return processingJobsForQueue.count;
    } else {
        return 0;
    }
}

- (int)maxConcurrentJobsPerQueue {
    return 3;
}

- (void)tick {
    if (self.isTicking) return;
    
    self.isTicking = true;

    for (NSString *queue in [self.engine allQueues]) {
        if ([self canProcessJobForQueue:queue]) {
            id job = [self fetchJobForQueue:queue];
            
            if ([self isJobValid:job]) {
                [self markJobProcessing:job];
                [self startJobProcessing:job];
            }
        }
    }
    
    self.isTicking = false;
}

- (id)fetchJobForQueue:(NSString *)queue {
    return [self.engine fetchJobForTaskName:queue excludeIDs:[self processingJobsForQueue:queue]];
}

- (BOOL)isJobValid:(id)job {
    return job && job[@"id"];
}

- (void)startJobProcessing:(id) job {
    dispatch_queue_t gcd = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0);
    dispatch_async(gcd, ^{
        if ([self.delegate respondsToSelector:@selector(queue:processJob:completion:)]) {
            [self.delegate queue:self processJob:job completion:^(EDQueueResult result) {
                [self processJob:job withResult:result];
            }];
        } else {
            EDQueueResult result = [self.delegate queue:self processJob:job];
            [self processJob:job withResult:result];
        }
    });
}

- (void)processJob:(NSDictionary*)job withResult:(EDQueueResult)result {
    dispatch_async(dispatch_get_main_queue(), ^{
        switch (result) {
            case EDQueueResultSuccess:
                [self performSelectorOnMainThread:@selector(postNotification:)
                                       withObject:[NSDictionary dictionaryWithObjectsAndKeys:EDQueueJobDidSucceed, @"name", job, @"data", nil]
                                    waitUntilDone:false];
                [self removeJob:job];
                
                break;
            case EDQueueResultFail:
                [self performSelectorOnMainThread:@selector(postNotification:)
                                       withObject:[NSDictionary dictionaryWithObjectsAndKeys:EDQueueJobDidFail, @"name", job, @"data", nil]
                                    waitUntilDone:true];
                
                NSUInteger currentAttempt = [[job objectForKey:@"attempts"] intValue] + 1;
                
                if (currentAttempt < self.retryLimit) {
                    [self.engine incrementAttemptForJob:[job objectForKey:@"id"]];
                } else {
                    [self removeJob:job];
                }
                
                break;
            case EDQueueResultCritical:
                [self performSelectorOnMainThread:@selector(postNotification:)
                                       withObject:[NSDictionary dictionaryWithObjectsAndKeys:EDQueueJobDidFail, @"name", job, @"data", nil]
                                    waitUntilDone:false];
                [self errorWithMessage:@"Critical error. Job canceled."];
                [self removeJob:job];
                
                break;
        }
        
        [self removeJobFromProcessing:job];
        [self processNextJob];
    });
}

- (void)removeJob:(id)job {
    [self.engine removeJob:[job objectForKey:@"id"]];
}

- (void)processNextJob {
    if ([self.engine fetchJobCount] == 0) {
        [self performSelectorOnMainThread:@selector(postNotification:)
                               withObject:[NSDictionary dictionaryWithObjectsAndKeys:EDQueueDidDrain, @"name", nil, @"data", nil]
                            waitUntilDone:false];
    } else {
        [self performSelectorOnMainThread:@selector(tick)
                               withObject:nil
                            waitUntilDone:false];
    }
}

- (void)postNotification:(NSDictionary *)object {
    [[NSNotificationCenter defaultCenter] postNotificationName:[object objectForKey:@"name"] object:[object objectForKey:@"data"]];
}

- (void)errorWithMessage:(NSString *)message {
    NSLog(@"EDQueue Error: %@", message);
}

@end

//
//  EDQueue.m
//  queue
//
//  Created by Andrew Sliwinski on 6/29/12.
//  Copyright (c) 2012 Andrew Sliwinski. All rights reserved.
//

#import "EDQueue.h"

//

@interface EDQueue ()
@property (readwrite) Boolean isRunning;
@property (readwrite) Boolean isActive;
@property FMDatabaseQueue *queue;
@property NSTimer *timer;
@end

//

@implementation EDQueue

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
    if (self) {
        // Setup
        _isRunning                      = false;
        _isActive                       = false;
        _retryLimit                     = 4;
        
        // Database path
        NSArray *paths                  = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask,YES);
        NSString *documentsDirectory    = [paths objectAtIndex:0];
        NSString *path                  = [documentsDirectory stringByAppendingPathComponent:@"edqueue_0.5.0c.db"];
        
        // Allocate the queue
        _queue                          = [[FMDatabaseQueue alloc] initWithPath:path];
        [self.queue inDatabase:^(FMDatabase *db) {
            [db executeUpdate:@"CREATE TABLE IF NOT EXISTS queue (id INTEGER PRIMARY KEY, task TEXT NOT NULL, data TEXT NOT NULL, attempts INTEGER DEFAULT 0, stamp STRING DEFAULT (strftime('%s','now')) NOT NULL, udef_1 TEXT, udef_2 TEXT)"];
            [self databaseHadError:[db hadError] fromDatabase:db];
        }];
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
    if (data == nil) data = @{};
    [self createJob:[NSJSONSerialization dataWithJSONObject:data options:NSJSONWritingPrettyPrinted error:nil] forTask:task];
    [self tick];
}

/**
 * Starts the queue.
 *
 * @return {void}
 */
- (void)start
{
    if (!self.isRunning) {
        self.isRunning = true;
        [self tick];
        [self performSelectorOnMainThread:@selector(postNotification:) withObject:[NSDictionary dictionaryWithObjectsAndKeys:@"EDQueueDidStart", @"name", nil, @"data", nil] waitUntilDone:false];
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
        self.isRunning = false;
        [self performSelectorOnMainThread:@selector(postNotification:) withObject:[NSDictionary dictionaryWithObjectsAndKeys:@"EDQueueDidStop", @"name", nil, @"data", nil] waitUntilDone:false];
    }
}

#pragma mark - Database helpers

- (Boolean)databaseHadError:(Boolean)flag fromDatabase:(FMDatabase *)db
{
    if (flag) NSLog(@"Queue Database Error %d: %@", [db lastErrorCode], [db lastErrorMessage]);
    return flag;
}

- (NSUInteger)jobCount
{
    __block NSUInteger count = 0;
    
    [self.queue inDatabase:^(FMDatabase *db) {
        FMResultSet *rs = [db executeQuery:@"SELECT count(id) AS count FROM queue"];
        [self databaseHadError:[db hadError] fromDatabase:db];
        
        while ([rs next]) {
            count = [rs intForColumn:@"count"];
        }
        
        [rs close];
    }];
    
    return count;
}

- (void)createJob:(id)data forTask:(id)task
{
    [self.queue inDatabase:^(FMDatabase *db) {
        [db executeUpdate:@"INSERT INTO queue (task, data) VALUES (?, ?)", task, data];
        [self databaseHadError:[db hadError] fromDatabase:db];
    }];
}

- (NSDictionary *)fetchJob
{
    __block id job;
    
    [self.queue inDatabase:^(FMDatabase *db) {
        FMResultSet *rs = [db executeQuery:@"SELECT * FROM queue ORDER BY id ASC LIMIT 1"];
        [self databaseHadError:[db hadError] fromDatabase:db];
        
        while ([rs next]) {
            job = @{
                @"id":          [NSNumber numberWithInt:[rs intForColumn:@"id"]],
                @"task":        [rs stringForColumn:@"task"],
                @"data":        [NSJSONSerialization JSONObjectWithData:[[rs stringForColumn:@"data"] dataUsingEncoding:NSUTF8StringEncoding] options:NSJSONReadingMutableContainers error:nil],
                @"attempts":    [NSNumber numberWithInt:[rs intForColumn:@"attempts"]],
                @"stamp":       [rs stringForColumn:@"stamp"]
            };
        }
        
        [rs close];
    }];
    
    return job;
}

- (void)removeJob:(NSNumber *)jid
{
    [self.queue inDatabase:^(FMDatabase *db) {
        [db executeUpdate:@"DELETE FROM queue WHERE id = ?", jid];
        [self databaseHadError:[db hadError] fromDatabase:db];
    }];
}

- (void)incrementAttemptForJob:(NSNumber *)jid
{
    [self.queue inDatabase:^(FMDatabase *db) {
        [db executeUpdate:@"UPDATE queue SET attempts = attempts + 1 WHERE id = ?", jid];
        [self databaseHadError:[db hadError] fromDatabase:db];
    }];
}

#pragma mark - Private methods

/**
 * Checks the queue for available jobs, sends them to the processor delegate, and handles the response.
 *
 * @return {void}
 */
- (void)tick
{
    dispatch_queue_t gcd = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0);
    dispatch_async(gcd, ^{
        if (self.isRunning && !self.isActive && [self jobCount] > 0) {
            // Start job
            self.isActive = true;
            id job = [self fetchJob];
            
            // Pass job to delegate
            EDQueueResult result = [self.delegate queue:self processJob:job];
            
            // Check result
            switch (result) {
                case EDQueueResultSuccess:
                    [self performSelectorOnMainThread:@selector(postNotification:) withObject:[NSDictionary dictionaryWithObjectsAndKeys:@"EDQueueJobDidSucceed", @"name", job, @"data", nil] waitUntilDone:false];
                    [self removeJob:[job objectForKey:@"id"]];
                    break;
                case EDQueueResultFail:
                    [self performSelectorOnMainThread:@selector(postNotification:) withObject:[NSDictionary dictionaryWithObjectsAndKeys:@"EDQueueJobDidFail", @"name", job, @"data", nil] waitUntilDone:true];
                    NSUInteger currentAttempt = [[job objectForKey:@"attempts"] intValue] + 1;
                    if (currentAttempt < self.retryLimit) {
                        [self incrementAttemptForJob:[job objectForKey:@"id"]];
                    } else {
                        [self removeJob:[job objectForKey:@"id"]];
                    }
                    break;
                case EDQueueResultCritical:
                    [self performSelectorOnMainThread:@selector(postNotification:) withObject:[NSDictionary dictionaryWithObjectsAndKeys:@"EDQueueJobDidFail", @"name", job, @"data", nil] waitUntilDone:false];
                    [self errorWithMessage:@"Critical error. Job canceled."];
                    [self removeJob:[job objectForKey:@"id"]];
                    break;
            }
            
            // Check drain
            if ([self jobCount] == 0) {
                [self performSelectorOnMainThread:@selector(postNotification:) withObject:[NSDictionary dictionaryWithObjectsAndKeys:@"EDQueueDidDrain", @"name", nil, @"data", nil] waitUntilDone:false];
            } else {
                [self performSelectorOnMainThread:@selector(tick) withObject:nil waitUntilDone:false];
            }
            
            // Clean-up
            self.isActive = false;
        }
    });
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
- (void)postNotification:(NSDictionary *)object
{
    [[NSNotificationCenter defaultCenter] postNotificationName:[object objectForKey:@"name"] object:[object objectForKey:@"data"]];
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

#pragma mark - Dealloc

- (void)dealloc
{    
    self.delegate = nil;
    
    _queue = nil;
}

@end

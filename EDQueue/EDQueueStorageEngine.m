//
//  EDQueueStorage.m
//  queue
//
//  Created by Andrew Sliwinski on 9/17/12.
//  Copyright (c) 2012 DIY, Co. All rights reserved.
//

#import "EDQueueStorageEngine.h"

#import "FMDatabase.h"
#import "FMDatabaseAdditions.h"
#import "FMDatabasePool.h"
#import "FMDatabaseQueue.h"

@implementation EDQueueStorageEngine

#pragma mark - Init

- (id)init
{
    self = [super init];
    if (self) {
        // Database path
        NSArray *paths                  = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask,YES);
        NSString *documentsDirectory    = [paths objectAtIndex:0];
        NSString *path                  = [documentsDirectory stringByAppendingPathComponent:@"edqueue_0.5.0d.db"];
        
        // Allocate the queue
        _queue                          = [[FMDatabaseQueue alloc] initWithPath:path];
        [self.queue inDatabase:^(FMDatabase *db) {
            [db executeUpdate:@"CREATE TABLE IF NOT EXISTS queue (id INTEGER PRIMARY KEY, task TEXT NOT NULL, data TEXT NOT NULL, attempts INTEGER DEFAULT 0, stamp STRING DEFAULT (strftime('%s','now')) NOT NULL, udef_1 TEXT, udef_2 TEXT)"];
            [self _databaseHadError:[db hadError] fromDatabase:db];
        }];
    }
    
    return self;
}

- (void)dealloc
{
    _queue = nil;
}

#pragma mark - Public methods

/**
 * Creates a new job within the datastore.
 *
 * @param {NSString} Data (JSON string)
 * @param {NSString} Task name
 *
 * @return {void}
 */
- (void)createJob:(id)data forTask:(id)task
{
    NSString *dataString = [[NSString alloc] initWithData:[NSJSONSerialization dataWithJSONObject:data options:NSJSONWritingPrettyPrinted error:nil] encoding:NSUTF8StringEncoding];
    
    [self.queue inDatabase:^(FMDatabase *db) {
        [db executeUpdate:@"INSERT INTO queue (task, data) VALUES (?, ?)", task, dataString];
        [self _databaseHadError:[db hadError] fromDatabase:db];
    }];
}

/**
 * Tells if a job exists for the specified task name.
 *
 * @param {NSString} Task name
 *
 * @return {BOOL}
 */
- (BOOL)jobExistsForTask:(id)task
{
    __block BOOL jobExists = NO;
    
    [self.queue inDatabase:^(FMDatabase *db) {
        FMResultSet *rs = [db executeQuery:@"SELECT count(id) AS count FROM queue WHERE task = ?", task];
        [self _databaseHadError:[db hadError] fromDatabase:db];
        
        while ([rs next]) {
            jobExists |= ([rs intForColumn:@"count"] > 0);
        }
        
        [rs close];
    }];
    
    return jobExists;
}

/**
 * Increments the "attempts" column for a specified job.
 *
 * @param {NSNumber} Job id
 *
 * @return {void}
 */
- (void)incrementAttemptForJob:(NSNumber *)jid
{
    [self.queue inDatabase:^(FMDatabase *db) {
        [db executeUpdate:@"UPDATE queue SET attempts = attempts + 1 WHERE id = ?", jid];
        [self _databaseHadError:[db hadError] fromDatabase:db];
    }];
}

/**
 * Removes a job from the datastore using a specified id.
 *
 * @param {NSNumber} Job id
 *
 * @return {void}
 */
- (void)removeJob:(NSNumber *)jid
{
    [self.queue inDatabase:^(FMDatabase *db) {
        [db executeUpdate:@"DELETE FROM queue WHERE id = ?", jid];
        [self _databaseHadError:[db hadError] fromDatabase:db];
    }];
}

/**
 * Removes all pending jobs from the datastore
 *
 * @return {void}
 *
 */
- (void)removeAllJobs {
    [self.queue inDatabase:^(FMDatabase *db) {
        [db executeUpdate:@"DELETE FROM queue"];
        [self _databaseHadError:[db hadError] fromDatabase:db];
    }];
}

/**
 * Returns the total number of jobs within the datastore.
 *
 * @return {uint}
 */
- (NSUInteger)fetchJobCount
{
    __block NSUInteger count = 0;
    
    [self.queue inDatabase:^(FMDatabase *db) {
        FMResultSet *rs = [db executeQuery:@"SELECT count(id) AS count FROM queue"];
        [self _databaseHadError:[db hadError] fromDatabase:db];
        
        while ([rs next]) {
            count = [rs intForColumn:@"count"];
        }
        
        [rs close];
    }];
    
    return count;
}

/**
 * Returns the oldest job from the datastore.
 *
 * @return {NSDictionary}
 */
- (NSDictionary *)fetchJob
{
    __block id job;
    
    [self.queue inDatabase:^(FMDatabase *db) {
        FMResultSet *rs = [db executeQuery:@"SELECT * FROM queue ORDER BY attempts ASC, id ASC LIMIT 1"];
        [self _databaseHadError:[db hadError] fromDatabase:db];
        
        while ([rs next]) {
            job = [self _jobFromResultSet:rs];
        }
        
        [rs close];
    }];
    
    return job;
}

/**
 * Returns the oldest job for the task from the datastore.
 *
 * @param {id} Task label
 *
 * @return {NSDictionary}
 */
- (NSDictionary *)fetchJobForTask:(id)task
{
    __block id job;
    
    [self.queue inDatabase:^(FMDatabase *db) {
        FMResultSet *rs = [db executeQuery:@"SELECT * FROM queue WHERE task = ? ORDER BY id ASC LIMIT 1", task];
        [self _databaseHadError:[db hadError] fromDatabase:db];
        
        while ([rs next]) {
            job = [self _jobFromResultSet:rs];
        }
        
        [rs close];
    }];
    
    return job;
}

- (NSArray *)getAllJobs
{
  __block id jobs = [[NSMutableArray alloc] init];
  [self.queue inDatabase:^(FMDatabase *db) {
    FMResultSet *rs = [db executeQuery:@"SELECT * FROM queue ORDER BY id ASC"];
    [self _databaseHadError:[db hadError] fromDatabase:db];
    while ([rs next]) {
      NSDictionary *job = [self _jobFromResultSet:rs];
      if (job) [jobs addObject:job];
    }
    [rs close];
  }];
  return jobs;
}

#pragma mark - Private methods

- (NSDictionary *)_jobFromResultSet:(FMResultSet *)rs
{
    NSDictionary *job = @{
        @"id":          [NSNumber numberWithInt:[rs intForColumn:@"id"]],
        @"task":        [rs stringForColumn:@"task"],
        @"data":        [NSJSONSerialization JSONObjectWithData:[[rs stringForColumn:@"data"] dataUsingEncoding:NSUTF8StringEncoding] options:NSJSONReadingMutableContainers error:nil],
        @"attempts":    [NSNumber numberWithInt:[rs intForColumn:@"attempts"]],
        @"stamp":       [rs stringForColumn:@"stamp"]
    };
    return job;
}

- (BOOL)_databaseHadError:(BOOL)flag fromDatabase:(FMDatabase *)db
{
    if (flag) NSLog(@"Queue Database Error %d: %@", [db lastErrorCode], [db lastErrorMessage]);
    return flag;
}

@end

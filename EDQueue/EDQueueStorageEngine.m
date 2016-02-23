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

#import "EDQueueJob.h"

NS_ASSUME_NONNULL_BEGIN

static NSString *pathForStorageName(NSString *storage)
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask,YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *path = [documentsDirectory stringByAppendingPathComponent:storage];

    return path;
}

@interface EDQueueStorageEngineJob : NSObject<EDQueueStorageItem>

- (instancetype)initWithTag:(NSString *)tag
                   userInfo:(nullable NSDictionary<id<NSCoding>, id<NSCoding>> *)userInfo
                      jobID:(nullable NSNumber *)jobID
                    atempts:(nullable NSNumber *)attemps
                  timeStamp:(nullable NSString *)timeStamp;

@end

@implementation EDQueueStorageEngineJob

@synthesize job = _job;
@synthesize jobID = _jobID;
@synthesize attempts = _attempts;
@synthesize timeStamp = _timeStamp;

- (instancetype)initWithTag:(NSString *)tag
                   userInfo:(nullable NSDictionary<id<NSCoding>, id<NSCoding>> *)userInfo
                      jobID:(nullable NSNumber *)jobID
                    atempts:(nullable NSNumber *)attemps
                  timeStamp:(nullable NSString *)timeStamp
{
    self = [super init];

    if (self) {

        _job = [[EDQueueJob alloc] initWithTag:tag userInfo:userInfo];
        _jobID = [jobID copy];
        _attempts = [attemps copy];
        _timeStamp = [timeStamp copy];
    }

    return self;
}

@end

@interface EDQueueStorageEngine()

@property (retain) FMDatabaseQueue *queue;

@end

@implementation EDQueueStorageEngine

#pragma mark - Class

+ (void)deleteDatabaseName:(NSString *)name
{
    [[NSFileManager defaultManager] removeItemAtPath:pathForStorageName(name) error:nil];
}

#pragma mark - Init

- (nullable instancetype)initWithName:(NSString *)name
{
    self = [super init];
    if (self) {
        _queue = [[FMDatabaseQueue alloc] initWithPath:pathForStorageName(name)];

        if (!_queue) {
            return nil;
        }

        [self.queue inDatabase:^(FMDatabase *db) {
            [db executeUpdate:@"CREATE TABLE IF NOT EXISTS queue (id INTEGER PRIMARY KEY, tag TEXT NOT NULL, data TEXT NOT NULL, attempts INTEGER DEFAULT 0, stamp STRING DEFAULT (strftime('%s','now')) NOT NULL, udef_1 TEXT, udef_2 TEXT)"];
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
 * @param {EDQueueJob} a Job
 *
 * @return {void}
 */
//- (void)createJob:(id)data forTask:(id)task
- (void)createJob:(EDQueueJob *)job
{
    NSString *dataString = nil;

    if (job.userInfo) {
        NSData *data = [NSJSONSerialization dataWithJSONObject:job.userInfo
                                                       options:NSJSONWritingPrettyPrinted
                                                         error:nil];

        dataString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    }
    
    [self.queue inDatabase:^(FMDatabase *db) {
        [db executeUpdate:@"INSERT INTO queue (tag, data) VALUES (?, ?)", job.tag, dataString];
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
- (BOOL)jobExistsForTag:(NSString *)tag
{
    __block BOOL jobExists = NO;
    
    [self.queue inDatabase:^(FMDatabase *db) {
        FMResultSet *rs = [db executeQuery:@"SELECT count(id) AS count FROM queue WHERE tag = ?", tag];
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
- (void)incrementAttemptForJob:(id<EDQueueStorageItem>)job
{
    if (!job.jobID) {
        return;
    }

    [self.queue inDatabase:^(FMDatabase *db) {
        [db executeUpdate:@"UPDATE queue SET attempts = attempts + 1 WHERE id = ?", job.jobID];
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
- (void)removeJob:(id<EDQueueStorageItem>)job
{
    if (!job.jobID) {
        return;
    }

    [self.queue inDatabase:^(FMDatabase *db) {
        [db executeUpdate:@"DELETE FROM queue WHERE id = ?", job.jobID];
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
- (NSUInteger)jobCount
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
- (nullable id<EDQueueStorageItem>)fetchNextJob
{
    __block id<EDQueueStorageItem> job;
    
    [self.queue inDatabase:^(FMDatabase *db) {
        FMResultSet *rs = [db executeQuery:@"SELECT * FROM queue ORDER BY id ASC LIMIT 1"];
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
- (nullable id<EDQueueStorageItem>)fetchNextJobForTag:(NSString *)tag
{
    __block id<EDQueueStorageItem> job;
    
    [self.queue inDatabase:^(FMDatabase *db) {
        FMResultSet *rs = [db executeQuery:@"SELECT * FROM queue WHERE tag = ? ORDER BY id ASC LIMIT 1", tag];
        [self _databaseHadError:[db hadError] fromDatabase:db];
        
        while ([rs next]) {
            job = [self _jobFromResultSet:rs];
        }
        
        [rs close];
    }];
    
    return job;
}

#pragma mark - Private methods

- (id<EDQueueStorageItem>)_jobFromResultSet:(FMResultSet *)rs
{
    NSDictionary *userInfo = [NSJSONSerialization JSONObjectWithData:[[rs stringForColumn:@"data"] dataUsingEncoding:NSUTF8StringEncoding] options:NSJSONReadingMutableContainers error:nil];

    EDQueueStorageEngineJob *job = [[EDQueueStorageEngineJob alloc] initWithTag:[rs stringForColumn:@"tag"]
                                                                       userInfo:userInfo
                                                                          jobID:@([rs intForColumn:@"id"])
                                                                        atempts:@([rs intForColumn:@"attempts"])
                                                                      timeStamp:[rs stringForColumn:@"stamp"]];

    return job;
}

- (BOOL)_databaseHadError:(BOOL)flag fromDatabase:(FMDatabase *)db
{
    if (flag) NSLog(@"Queue Database Error %d: %@", [db lastErrorCode], [db lastErrorMessage]);
    return flag;
}

@end

NS_ASSUME_NONNULL_END
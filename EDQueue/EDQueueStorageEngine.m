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

static NSTimeInterval const DefaultJobSleepInteval = 5.0;
static NSTimeInterval const MaxJobSleepInterval = 60.0;


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
                    atempts:(nullable NSNumber *)attemps;

@end

@implementation EDQueueStorageEngineJob

@synthesize job = _job;
@synthesize jobID = _jobID;
@synthesize attempts = _attempts;

- (instancetype)initWithTag:(NSString *)tag
                   userInfo:(nullable NSDictionary<id<NSCoding>, id<NSCoding>> *)userInfo
                      jobID:(nullable NSNumber *)jobID
                    atempts:(nullable NSNumber *)attemps
{
    self = [super init];

    if (self) {

        _job = [[EDQueueJob alloc] initWithTag:tag userInfo:userInfo];
        _jobID = [jobID copy];
        _attempts = [attemps copy];
    }

    return self;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"%@ : id:%@, tag: %@",NSStringFromClass([self class]), _jobID, _job.tag];
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

        [_queue inDatabase:^(FMDatabase *db) {
            [db executeUpdate:@"CREATE TABLE IF NOT EXISTS queue (id INTEGER PRIMARY KEY, tag TEXT NOT NULL, data TEXT NOT NULL, attempts INTEGER DEFAULT 0, maxAttempts INTEGER DEFAULT 0, expiration DOUBLE DEFAULT 0, retryTimeInterval DOUBLE DEFAULT 30, lastAttempt DOUBLE DEFAULT 0 )"];
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
- (void)createJob:(EDQueueJob *)job
{
    if (!job.userInfo) {
        @throw [NSException exceptionWithName:NSInvalidArgumentException reason:@"EDQueueJob.userInfo can not be nil" userInfo:nil];
    }

    NSData *data = [NSJSONSerialization dataWithJSONObject:job.userInfo
                                                       options:NSJSONWritingPrettyPrinted
                                                         error:nil];

    NSString *dataString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];


    [self.queue inDatabase:^(FMDatabase *db) {

        NSTimeInterval expiration = job.expirationDate.timeIntervalSince1970;

        if (expiration == 0) {
            expiration = [NSDate distantFuture].timeIntervalSince1970;
        }

        [db executeUpdate:@"INSERT INTO queue (tag, data, maxAttempts, expiration, retryTimeInterval) VALUES (?, ?, ?, ?, ?)", job.tag, dataString, @(job.maxRetryCount), @(expiration), @(job.retryTimeInterval)];
        [self _databaseHadError:[db hadError] fromDatabase:db];
    }];
}

/**
 * Tells if a job exists for the specified tag
 *
 * @param {NSString} tag
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
- (void)scheduleNextAttemptForJob:(id<EDQueueStorageItem>)job
{
    if (!job.jobID) {
        return;
    }

    [self.queue inDatabase:^(FMDatabase *db) {
        [db executeUpdate:@"UPDATE queue SET attempts = attempts + 1, lastAttempt = ? WHERE id = ?", @([NSDate date].timeIntervalSince1970 + job.job.retryTimeInterval), job.jobID];
        [self _databaseHadError:[db hadError] fromDatabase:db];
    }];
}

/**
 * Removes a job from the datastore using a specified id. And also removes all Expired jobs. 
 * (aka clean-up)
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
        NSNumber *expiration = @([NSDate date].timeIntervalSince1970);
        [db executeUpdate:@"DELETE FROM queue WHERE id = ? OR expiration < ?", job.jobID, expiration];
        [self _databaseHadError:[db hadError] fromDatabase:db];
    }];
}

/**
 * Removes all pending jobs from the datastore
 *
 * @return {void}
 *
 */
- (void)removeAllJobs
{
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
        FMResultSet *rs = [db executeQuery:@"SELECT count(id) AS count FROM queue WHERE expiration >= ? ",@([NSDate date].timeIntervalSince1970)];
        [self _databaseHadError:[db hadError] fromDatabase:db];
        
        while ([rs next]) {
            count = [rs intForColumn:@"count"];
        }
        
        [rs close];
    }];
    
    return count;
}

/**
 * Returns the oldest valid job from the datastore.
 *
 * @return {id<EDQueueStorageItem>}
 */
- (nullable id<EDQueueStorageItem>)fetchNextJobValidForDate:(NSDate *)date
{
    __block id<EDQueueStorageItem> job;
    
    [self.queue inDatabase:^(FMDatabase *db) {
        NSTimeInterval timestamp = date.timeIntervalSince1970;
        FMResultSet *rs = [db executeQuery:@"SELECT * FROM queue WHERE lastAttempt <= ? AND expiration >= ? ORDER BY id ASC LIMIT 1", @(timestamp), @(timestamp)];
        [self _databaseHadError:[db hadError] fromDatabase:db];
        
        while ([rs next]) {
            job = [self _jobFromResultSet:rs];
        }
        
        [rs close];
    }];
    
    return job;
}

/**
 * Returns the oldest valid job from the datastore with specific tag
 *
 * @return {id<EDQueueStorageItem>}
 */
- (nullable id<EDQueueStorageItem>)fetchNextJobForTag:(NSString *)tag validForDate:(NSDate *)date
{
    __block id<EDQueueStorageItem> job;

    [self.queue inDatabase:^(FMDatabase *db) {
        NSTimeInterval timestamp = date.timeIntervalSince1970;
        FMResultSet *rs = [db executeQuery:@"SELECT * FROM queue WHERE tag = ? AND lastAttempt <= ? AND expiration >= ? ORDER BY id ASC LIMIT 1", tag, @(timestamp), @(timestamp)];
        [self _databaseHadError:[db hadError] fromDatabase:db];

        while ([rs next]) {
            job = [self _jobFromResultSet:rs];
        }

        [rs close];
    }];

    return job;
}

/**
 * Returns the minumum timeout for starting the next job.
 *
 * @param {id} tag
 *
 * @return {id<EDQueueStorageItem>}
 */
- (NSTimeInterval)fetchNextJobTimeInterval
{

    __block NSTimeInterval timeInterval = DefaultJobSleepInteval;

    [self.queue inDatabase:^(FMDatabase *db) {

        FMResultSet *rs = [db executeQuery:@"SELECT * FROM queue WHERE lastAttempt < expiration ORDER BY lastAttempt ASC LIMIT 1"];
        [self _databaseHadError:[db hadError] fromDatabase:db];
        
        while ([rs next]) {
            timeInterval = [rs doubleForColumn:@"lastAttempt"];

            timeInterval = fabs(timeInterval - [NSDate date].timeIntervalSince1970);

            if (timeInterval > MaxJobSleepInterval) {
                timeInterval = MaxJobSleepInterval;
            }
        }
        
        [rs close];
    }];
    
    return timeInterval;
}

#pragma mark - Private methods

- (id<EDQueueStorageItem>)_jobFromResultSet:(FMResultSet *)rs
{
    NSDictionary *userInfo = [NSJSONSerialization JSONObjectWithData:[[rs stringForColumn:@"data"] dataUsingEncoding:NSUTF8StringEncoding] options:NSJSONReadingMutableContainers error:nil];

    EDQueueStorageEngineJob *storedItem = [[EDQueueStorageEngineJob alloc] initWithTag:[rs stringForColumn:@"tag"]
                                                                       userInfo:userInfo
                                                                          jobID:@([rs intForColumn:@"id"])
                                                                        atempts:@([rs intForColumn:@"attempts"])];

    storedItem.job.maxRetryCount = [rs intForColumn:@"maxAttempts"];
    storedItem.job.retryTimeInterval = [rs doubleForColumn:@"retryTimeInterval"];

    NSTimeInterval expiration = [rs doubleForColumn:@"expiration"];

    storedItem.job.expirationDate = [NSDate dateWithTimeIntervalSince1970:expiration];


    return storedItem;
}

- (BOOL)_databaseHadError:(BOOL)flag fromDatabase:(FMDatabase *)db
{
    if (flag) NSLog(@"Queue Database Error %d: %@", [db lastErrorCode], [db lastErrorMessage]);
    return flag;
}

@end

NS_ASSUME_NONNULL_END
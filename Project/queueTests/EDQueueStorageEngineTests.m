//
//  EDQueueStorageEngineTests.m
//  queue
//
//  Created by Oleg Shanyuk on 24/02/16.
//  Copyright © 2016 DIY, Co. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "EDQueueStorageEngine.h"
#import "EDQueueJob.h"

@interface EDQueueStorageEngineTests : XCTestCase

@end

@implementation EDQueueStorageEngineTests

- (void)tearDown {

    [EDQueueStorageEngine deleteDatabaseName:@"test.db"];

    [super tearDown];
}

- (void)testDefaultJobAdded
{
    EDQueueStorageEngine *testEngine = [[EDQueueStorageEngine alloc] initWithName:@"test.db"];

    EDQueueJob *job = [[EDQueueJob alloc] initWithTag:@"tag" userInfo:@{@"user":@"info"}];

    [testEngine createJob:job];

    id<EDQueueStorageItem> item = [testEngine fetchNextJobValidForDate:[NSDate date]];

    XCTAssertNotNil(item);

    XCTAssertEqual(item.job.expirationDate, [NSDate distantFuture]);
    XCTAssertEqual(item.job.retryTimeInterval, job.retryTimeInterval);
    XCTAssertEqual(item.job.maxRetryCount, job.maxRetryCount);

    XCTAssertEqualObjects(item.job.userInfo, job.userInfo);
    XCTAssertEqualObjects(item.job.tag, job.tag);
}

- (void)testAddExpiredJob
{
    EDQueueStorageEngine *testEngine = [[EDQueueStorageEngine alloc] initWithName:@"test.db"];

    EDQueueJob *job = [[EDQueueJob alloc] initWithTag:@"tag" userInfo:@{@"user":@"info"}];

    job.expirationDate = [[NSDate date] dateByAddingTimeInterval:-1];

    id<EDQueueStorageItem> item = [testEngine fetchNextJobValidForDate:[NSDate date]];

    XCTAssertNil(item);
}

- (void)testJobCountOnEmptyDatabase
{
    EDQueueStorageEngine *testEngine = [[EDQueueStorageEngine alloc] initWithName:@"test.db"];

    XCTAssertEqual([testEngine jobCount], 0);
}

- (void)testJobCountWithExpiredJobs
{
    EDQueueStorageEngine *testEngine = [[EDQueueStorageEngine alloc] initWithName:@"test.db"];

    EDQueueJob *job = [[EDQueueJob alloc] initWithTag:@"tag" userInfo:@{@"user":@"info"}];

    job.expirationDate = [[NSDate date] dateByAddingTimeInterval:-1];

    XCTAssertEqual([testEngine jobCount], 0);
}

- (void)testJobCountWithOneJob
{
    EDQueueStorageEngine *testEngine = [[EDQueueStorageEngine alloc] initWithName:@"test.db"];

    EDQueueJob *job = [[EDQueueJob alloc] initWithTag:@"tag" userInfo:@{@"user":@"info"}];

    [testEngine createJob:job];

    XCTAssertEqual([testEngine jobCount], 1);
}


- (void)testAddJobThatExpires
{
    EDQueueStorageEngine *testEngine = [[EDQueueStorageEngine alloc] initWithName:@"test.db"];

    EDQueueJob *job = [[EDQueueJob alloc] initWithTag:@"tag" userInfo:@{@"user":@"info"}];

    NSDate *expirationDate = [NSDate date];

    job.expirationDate = expirationDate;

    [testEngine createJob:job];

    id<EDQueueStorageItem> itemInvalid = [testEngine fetchNextJobValidForDate:[expirationDate dateByAddingTimeInterval:1]];

    XCTAssertNil(itemInvalid);

    id<EDQueueStorageItem> itemValid = [testEngine fetchNextJobValidForDate:[expirationDate dateByAddingTimeInterval:-1]];

    XCTAssertNotNil(itemValid);
}

- (void)testScheduleNextAttemptForJob
{
    EDQueueStorageEngine *testEngine = [[EDQueueStorageEngine alloc] initWithName:@"test.db"];

    EDQueueJob *job = [[EDQueueJob alloc] initWithTag:@"tag" userInfo:@{@"user":@"info"}];

    [testEngine createJob:job];

    id<EDQueueStorageItem> item = [testEngine fetchNextJobValidForDate:[NSDate date]];

    XCTAssertEqual(item.attempts.integerValue, 0);

    [testEngine scheduleNextAttemptForJob:item];

    id<EDQueueStorageItem> itemIncreased = [testEngine fetchNextJobValidForDate:[[NSDate date] dateByAddingTimeInterval:job.retryTimeInterval]];

    XCTAssertEqual(itemIncreased.attempts.integerValue, 1);
}

@end

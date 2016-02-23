//
//  EDQueueTests.m
//  queue
//
//  Created by Oleg Shanyuk on 19/02/16.
//  Copyright © 2016 DIY, Co. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "EDQueue.h"
#import "EDQueueStorageEngine.h"

NSString *const EQTestDatabaseName = @"database.test.sqlite";

@interface EDQueueTests : XCTestCase<EDQueueDelegate>
@property (nonatomic) EDQueue *queue;
@property (nonatomic) XCTestExpectation *currentExpectation;
@end

@implementation EDQueueTests

-(void)queue:(EDQueue *)queue processJob:(EDQueueJob *)job completion:(EDQueueCompletionBlock)block
{
    [self.currentExpectation fulfill];

    block(EDQueueResultSuccess);
}

- (void)setUp {
    EDQueueStorageEngine *fmdbBasedStorage = [[EDQueueStorageEngine alloc] initWithName:EQTestDatabaseName];

    self.queue = [[EDQueue alloc] initWithPersistentStore:fmdbBasedStorage];

    self.currentExpectation = nil;
}

- (void)tearDown
{
    self.queue = nil;

    self.currentExpectation = nil;

    [EDQueueStorageEngine deleteDatabaseName:EQTestDatabaseName];
}

- (void)testQueueStart
{
    [self.queue start];

    XCTAssertTrue(self.queue.isRunning);
}

- (void)testQueueStop
{
    [self.queue start];
    [self.queue stop];

    XCTAssertFalse(self.queue.isRunning);
}

- (void)testQueueStartThenAddJob
{
    EDQueueJob *job = [[EDQueueJob alloc] initWithTag:@"testTask" userInfo:@{}];

    self.queue.delegate = self;

    self.currentExpectation = [self expectationWithDescription:@"queue should start soon"];

    [self.queue start];

    [self.queue enqueueJob:job];

    [self waitForExpectationsWithTimeout:0.5 handler:nil];
}

- (void)testQueueAddJobThenStart
{
    EDQueueJob *job = [[EDQueueJob alloc] initWithTag:@"testTask" userInfo:@{}];

    self.queue.delegate = self;

    self.currentExpectation = [self expectationWithDescription:@"queue should start soon"];

    [self.queue enqueueJob:job];

    [self.queue start];

    [self waitForExpectationsWithTimeout:0.5 handler:nil];
}

- (void)testJobExistsForTaskAndEmpty
{
    EDQueueJob *job = [[EDQueueJob alloc] initWithTag:@"testTask" userInfo:@{}];

    [self.queue enqueueJob:job];

    XCTAssertTrue([self.queue jobExistsForTag:@"testTask"]);

    [self.queue empty];

    XCTAssertFalse([self.queue jobExistsForTag:@"testTask"]);
}

- (void)testJobDoesNotExistForTask
{
    EDQueueJob *job = [[EDQueueJob alloc] initWithTag:@"testTask" userInfo:@{}];

    [self.queue enqueueJob:job];

    XCTAssertFalse([self.queue jobExistsForTag:@"testTaskFalse"]);
}


- (void)testJobIsActiveForTask
{
    EDQueueJob *job = [[EDQueueJob alloc] initWithTag:@"testTask" userInfo:@{}];

    [self.queue enqueueJob:job];

    XCTAssertFalse([self.queue jobIsActiveForTag:@"testTask"]);

    [self.queue start];

    sleep(1);

    XCTAssertTrue([self.queue jobIsActiveForTag:@"testTask"]);
}

-(void)testNextJobForTask
{
    EDQueueJob *job = [[EDQueueJob alloc] initWithTag:@"testTask" userInfo:@{@"testId":@"uniqueForThisTest"}];

    [self.queue enqueueJob:job];

    EDQueueJob *nextJob = [self.queue nextJobForTag:@"testTask"];

    XCTAssertNotNil(nextJob);

    XCTAssertEqualObjects(nextJob.userInfo[@"testId"], @"uniqueForThisTest");
}

- (void)testIfQueuePersists
{
    EDQueueJob *job = [[EDQueueJob alloc] initWithTag:@"testTaskUniqueName" userInfo:@{@"test":@"test"}];

    [self.queue enqueueJob:job];

    self.queue = nil;

    [self setUp];

    XCTAssertTrue([self.queue jobExistsForTag:@"testTaskUniqueName"]);
}


@end

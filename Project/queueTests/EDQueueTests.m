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

static NSString *const EQTestDatabaseName = @"database.test.sqlite";
static NSString *const EQExpectationKey = @"EK";

@interface EDQueueTests : XCTestCase<EDQueueDelegate>
@property (nonatomic) EDQueue *queue;
@property (nonatomic) NSMutableDictionary *expectationHashes;
@end

@implementation EDQueueTests

-(void)queue:(EDQueue *)queue processJob:(EDQueueJob *)job completion:(EDQueueCompletionBlock)block
{
    NSString *expectationHash = (NSString *)job.userInfo[EQExpectationKey];

    XCTestExpectation *expectation = self.expectationHashes[expectationHash];

    NSLog(@"Testing(%p): %@ -> %@", self, expectationHash, expectation);

    [expectation fulfill];

    block(EDQueueResultSuccess);
}

- (void)setUp {
    EDQueueStorageEngine *fmdbBasedStorage = [[EDQueueStorageEngine alloc] initWithName:EQTestDatabaseName];

    self.queue = [[EDQueue alloc] initWithPersistentStore:fmdbBasedStorage];

    self.queue.delegate = self;

    self.expectationHashes = [NSMutableDictionary dictionary];
}

- (void)tearDown
{
    self.queue = nil;

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
    XCTestExpectation *expectation = [self expectationWithDescription:@"testQueueStartThenAddJob"];

    NSString *expectationHash = [NSString stringWithFormat:@"%p", expectation];

    self.expectationHashes[expectationHash] = expectation;

    EDQueueJob *job = [[EDQueueJob alloc] initWithTag:@"testTask" userInfo:@{EQExpectationKey : expectationHash}];

    NSLog(@"Added: %@", expectationHash);

    [self.queue start];

    [self.queue enqueueJob:job];

    [self waitForExpectationsWithTimeout:1000.5 handler:nil];
}

- (void)testQueueAddJobThenStart
{
    XCTestExpectation *expectation = [self expectationWithDescription:@"testQueueAddJobThenStart"];

    NSString *expectationHash = [NSString stringWithFormat:@"%p", expectation];

    self.expectationHashes[expectationHash] = expectation;

    EDQueueJob *job = [[EDQueueJob alloc] initWithTag:@"testTask" userInfo:@{EQExpectationKey : expectationHash}];

    [self.queue enqueueJob:job];

    [self.queue start];

    [self waitForExpectationsWithTimeout:0.5 handler:nil];
}

- (void)testJobExistsForTagAndEmpty
{
    EDQueueJob *job = [[EDQueueJob alloc] initWithTag:@"testTask" userInfo:@{}];

    self.queue.delegate = nil; // queue won't be able to complete task w/o delegate. so, we have time to check it

    [self.queue enqueueJob:job];

    XCTAssertTrue([self.queue jobExistsForTag:@"testTask"]);

    [self.queue empty];

    XCTAssertFalse([self.queue jobExistsForTag:@"testTask"]);
}

- (void)testJobDoesNotExistForTag
{
    EDQueueJob *job = [[EDQueueJob alloc] initWithTag:@"testTask" userInfo:@{}];

    self.queue.delegate = nil; // queue won't be able to complete task w/o delegate. so, we have time to check it

    [self.queue enqueueJob:job];

    XCTAssertFalse([self.queue jobExistsForTag:@"testTaskFalse"]);
}


- (void)testJobIsActiveForTag
{
    EDQueueJob *job = [[EDQueueJob alloc] initWithTag:@"testTask" userInfo:@{}];

    self.queue.delegate = nil; // queue won't be able to complete task w/o delegate. so, we have time to check it

    [self.queue enqueueJob:job];

    XCTAssertFalse([self.queue jobIsActiveForTag:@"testTask"]);

    [self.queue start];

    sleep(1);

    XCTAssertTrue([self.queue jobIsActiveForTag:@"testTask"]);
}

-(void)testNextJobForTag
{
    EDQueueJob *job = [[EDQueueJob alloc] initWithTag:@"testTask" userInfo:@{@"testId":@"uniqueForThisTest"}];

    self.queue.delegate = nil; // queue won't be able to complete task w/o delegate. so, we have time to check it

    [self.queue enqueueJob:job];

    EDQueueJob *nextJob = [self.queue nextJobForTag:@"testTask"];

    XCTAssertNotNil(nextJob);

    XCTAssertEqualObjects(nextJob.userInfo[@"testId"], @"uniqueForThisTest");
}

- (void)testIfQueuePersists
{
    EDQueueJob *job = [[EDQueueJob alloc] initWithTag:@"testTaskUniqueName" userInfo:@{@"test":@"test"}];

    self.queue.delegate = nil; // queue won't be able to complete task w/o delegate. so, we have time to check it

    [self.queue enqueueJob:job];

    self.queue = nil;

    [self setUp];

    XCTAssertTrue([self.queue jobExistsForTag:@"testTaskUniqueName"]);
}


@end

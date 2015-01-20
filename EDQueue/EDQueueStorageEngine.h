//
//  EDQueueStorage.h
//  queue
//
//  Created by Andrew Sliwinski on 9/17/12.
//  Copyright (c) 2012 DIY, Co. All rights reserved.
//

#import <Foundation/Foundation.h>

@class FMDatabaseQueue;
@interface EDQueueStorageEngine : NSObject

@property (retain) FMDatabaseQueue *queue;

- (void)createJob:(id)data forTask:(id)task;
- (void)createJob:(id)data forTask:(id)task runAfter:(NSDate*)runAfter;
- (BOOL)jobExistsForTask:(id)task;
- (void)incrementAttemptForJob:(NSNumber *)jid;
- (void)removeJob:(NSNumber *)jid;
- (void)removeAllJobs;
- (NSUInteger)fetchJobCount;
- (NSDictionary *)fetchJob;
- (NSDictionary *)fetchJobForTask:(id)task;

@end
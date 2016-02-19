//
//  EDQueueStorage.h
//  queue
//
//  Created by Andrew Sliwinski on 9/17/12.
//  Copyright (c) 2012 DIY, Co. All rights reserved.
//

@import Foundation;

NS_ASSUME_NONNULL_BEGIN

@class EDQueueJob;

@interface EDQueueStorageEngine : NSObject

- (void)createJob:(EDQueueJob *)job;
- (BOOL)jobExistsForTask:(NSString *)task;
- (void)incrementAttemptForJob:(EDQueueJob *)jid;
- (void)removeJob:(EDQueueJob *)jid;
- (void)removeAllJobs;
- (NSUInteger)fetchJobCount;
- (nullable EDQueueJob *)fetchJob;
- (nullable EDQueueJob *)fetchJobForTask:(NSString *)task;

@end

NS_ASSUME_NONNULL_END
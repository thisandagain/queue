//
//  EDQueuePersistentStorageProtocol.h
//  queue
//
//  Created by Oleg Shanyuk on 19/02/16.
//  Copyright © 2016 DIY, Co. All rights reserved.
//

@import Foundation;

NS_ASSUME_NONNULL_BEGIN

@class EDQueueJob;

@protocol EDQueuePersistentStorage <NSObject>

- (void)createJob:(EDQueueJob *)job;
- (BOOL)jobExistsForTask:(NSString *)task;
- (void)incrementAttemptForJob:(EDQueueJob *)jid;

- (void)removeJob:(EDQueueJob *)jid;
- (void)removeAllJobs;

- (NSUInteger)jobCount;
- (nullable EDQueueJob *)fetchNextJob;
- (nullable EDQueueJob *)fetchNextJobForTask:(NSString *)task;

@end

NS_ASSUME_NONNULL_END
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


@protocol EDQueueStorageItem <NSObject>

@property(nonatomic, readonly) EDQueueJob *job;

@property(nonatomic, readonly, nullable) NSNumber *jobID;
@property(nonatomic, readonly, nullable) NSNumber *attempts;

@end


@protocol EDQueuePersistentStorage <NSObject>

- (void)createJob:(EDQueueJob *)job;
- (BOOL)jobExistsForTag:(NSString *)tag;
- (void)scheduleNextAttemptForJob:(id<EDQueueStorageItem>)jid;

- (void)removeJob:(id<EDQueueStorageItem>)jid;
- (void)removeAllJobs;

- (NSUInteger)jobCount;
- (nullable id<EDQueueStorageItem>)fetchNextJobValidForDate:(NSDate *)date;
- (nullable id<EDQueueStorageItem>)fetchNextJobForTag:(NSString *)tag validForDate:(NSDate *)date;

@end

NS_ASSUME_NONNULL_END
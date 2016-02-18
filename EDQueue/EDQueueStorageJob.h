//
//  EDQueueJob.h
//  queue
//
//  Created by Oleg Shanyuk on 18/02/16.
//  Copyright © 2016 DIY, Co. All rights reserved.
//

#import <Foundation/Foundation.h>


extern NSString *const EDQueueStorageJobIdKey;
extern NSString *const EDQueueStorageJobTaskKey;
extern NSString *const EDQueueStorageJobDataKey;
extern NSString *const EDQueueStorageJobAttemptsKey;
extern NSString *const EDQueueStorageJobStampKey;

@interface EDQueueStorageJob : NSObject

@property (nonatomic, readonly) NSNumber *jobId;
@property (nonatomic, readonly) NSString *task;
@property (nonatomic, readonly) NSData *data;
@property (nonatomic, readonly) NSNumber* attempts;
@property (nonatomic, readonly) NSString *stamp;
@property (nonatomic, readonly) NSDictionary *dictionaryRepresentation;

- (instancetype)initWithDictionary:(NSDictionary *)dictionary;
- (instancetype)init NS_UNAVAILABLE;

- (NSDictionary*)dictionaryRepresentation;

@end

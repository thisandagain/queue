//
//  EDQueueJob.m
//  queue
//
//  Created by Oleg Shanyuk on 18/02/16.
//  Copyright © 2016 DIY, Co. All rights reserved.
//

#import "EDQueueStorageJob.h"

NSString *const EDQueueStorageJobIdKey = @"id";
NSString *const EDQueueStorageJobTaskKey = @"task";
NSString *const EDQueueStorageJobDataKey = @"data";
NSString *const EDQueueStorageJobAttemptsKey = @"atempts";
NSString *const EDQueueStorageJobStampKey = @"stamp";

@implementation EDQueueStorageJob

- (instancetype)initWithDictionary:(NSDictionary *)dictionary
{
    self = [super init];

    if (self) {
        _jobId = [dictionary[EDQueueStorageJobIdKey] copy];
        _task = [dictionary[EDQueueStorageJobTaskKey] copy];
        _data = [dictionary[EDQueueStorageJobDataKey] copy];
        _attempts = [dictionary[EDQueueStorageJobAttemptsKey] copy];
        _stamp = [dictionary[EDQueueStorageJobStampKey] copy];
    }

    return self;
}

- (NSDictionary *)dictionaryRepresentation
{
    return @{
             EDQueueStorageJobIdKey : _jobId,
             EDQueueStorageJobTaskKey : _task,
             EDQueueStorageJobDataKey : _data,
             EDQueueStorageJobAttemptsKey : _attempts,
             EDQueueStorageJobStampKey : _stamp
             };
}

@end

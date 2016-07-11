//
//  EDQueueJob.m
//  queue
//
//  Created by Oleg Shanyuk on 18/02/16.
//  Copyright © 2016 DIY, Co. All rights reserved.
//

#import "EDQueueJob.h"

NS_ASSUME_NONNULL_BEGIN

@implementation EDQueueJob

- (instancetype)initWithTag:(NSString *)tag
                   userInfo:(nullable NSDictionary<id<NSCoding>, id<NSCoding>> *)userInfo
{
    self = [super init];

    if (self) {
        _tag = [tag copy];
        _userInfo =  userInfo ? [userInfo copy] : @{};
        _maxRetryCount = EDQueueJobInfiniteRetryCount;
        _retryTimeInterval = EDQueueJobDefaultRetryTimeInterval;
        _expirationDate = [NSDate distantFuture];
    }

    return self;
}

@end

NS_ASSUME_NONNULL_END

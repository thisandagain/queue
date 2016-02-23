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

- (instancetype)initWithTask:(NSString *)task
                    userInfo:(nullable NSDictionary *)userInfo
{
    self = [super init];

    if (self) {
        _task = [task copy];
        _userInfo =  userInfo ? [userInfo copy] : @{};
    }

    return self;
}

@end

NS_ASSUME_NONNULL_END

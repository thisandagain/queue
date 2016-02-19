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
                       jobID:(nullable NSNumber *)jobID
                     atempts:(nullable NSNumber *)attemps
                   timeStamp:(nullable NSString *)timeStamp
{
  self = [super init];

  if (self) {
      _jobID = [jobID copy];
      _task = [task copy];
      _userInfo =  userInfo ? [userInfo copy] : @{};
      _attempts = [attemps copy];
      _timeStamp = [timeStamp copy];
  }

  return self;
}

- (instancetype)initWithTask:(NSString *)task
                    userInfo:(nullable NSDictionary *)userInfo
{
    return [self initWithTask:task userInfo:userInfo jobID:nil atempts:nil timeStamp:nil];
}

@end

NS_ASSUME_NONNULL_END

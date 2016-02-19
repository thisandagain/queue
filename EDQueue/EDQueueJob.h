//
//  EDQueueJob.h
//  queue
//
//  Created by Oleg Shanyuk on 18/02/16.
//  Copyright © 2016 DIY, Co. All rights reserved.
//

@import Foundation;

NS_ASSUME_NONNULL_BEGIN

@interface EDQueueJob : NSObject

@property(nonatomic, readonly) NSString *task;
@property(nonatomic, readonly) NSDictionary *userInfo;

@property(nonatomic, readonly, nullable) NSNumber *jobID;
@property(nonatomic, readonly, nullable) NSNumber *attempts;
@property(nonatomic, readonly, nullable) NSString *timeStamp;

- (instancetype)initWithTask:(NSString *)task
                    userInfo:(nullable NSDictionary *)userInfo
                       jobID:(nullable NSNumber *)jobID
                     atempts:(nullable NSNumber *)attemps
                   timeStamp:(nullable NSString *)timeStamp;

- (instancetype)initWithTask:(NSString *)task
                    userInfo:(nullable NSDictionary *)userInfo;

- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
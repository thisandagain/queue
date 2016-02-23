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

@property(nonatomic, readonly) NSString *tag;
@property(nonatomic, readonly) NSDictionary<id<NSCoding>, id<NSCoding>> *userInfo;

- (instancetype)initWithTag:(NSString *)tag
                   userInfo:(nullable NSDictionary<id<NSCoding>, id<NSCoding>> *)userInfo;

- (instancetype)init NS_UNAVAILABLE;

@end


NS_ASSUME_NONNULL_END
//
//  EDQueueStorage.h
//  queue
//
//  Created by Andrew Sliwinski on 9/17/12.
//  Copyright (c) 2012 DIY, Co. All rights reserved.
//

@import Foundation;

#import "EDQueuePersistentStorageProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@class EDQueueJob;

@interface EDQueueStorageEngine : NSObject<EDQueuePersistentStorage>

- (nullable instancetype)initWithName:(NSString *)name;
- (instancetype)init NS_UNAVAILABLE;

+ (void)deleteDatabaseName:(NSString *)name;

@end

NS_ASSUME_NONNULL_END
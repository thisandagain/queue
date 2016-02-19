//
//  EDQueue.h
//  queue
//
//  Created by Andrew Sliwinski on 6/29/12.
//  Copyright (c) 2012 Andrew Sliwinski. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "EDQueueJob.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, EDQueueResult) {
    EDQueueResultSuccess = 0,
    EDQueueResultFail,
    EDQueueResultCritical
};

typedef void (^EDQueueCompletionBlock)(EDQueueResult result);

extern NSString *const EDQueueDidStart;
extern NSString *const EDQueueDidStop;
extern NSString *const EDQueueJobDidSucceed;
extern NSString *const EDQueueJobDidFail;
extern NSString *const EDQueueDidDrain;

extern NSString *const EDQueueNameKey;
extern NSString *const EDQueueDataKey;


@protocol EDQueueDelegate;

@interface EDQueue : NSObject

+ (EDQueue *)sharedInstance;

@property (nonatomic, weak) id<EDQueueDelegate> delegate;

@property (nonatomic, readonly) BOOL isRunning;
@property (nonatomic, readonly) BOOL isActive;
@property (nonatomic) NSUInteger retryLimit;

- (void)enqueueJob:(EDQueueJob *)job;
- (void)start;
- (void)stop;
- (void)empty;

- (BOOL)jobExistsForTask:(NSString *)task;
- (BOOL)jobIsActiveForTask:(NSString *)task;
- (nullable EDQueueJob *)nextJobForTask:(NSString *)task;

@end

@protocol EDQueueDelegate <NSObject>
- (void)queue:(EDQueue *)queue processJob:(EDQueueJob *)job completion:(EDQueueCompletionBlock)block;
@end

NS_ASSUME_NONNULL_END
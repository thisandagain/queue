//
//  EDQueue.h
//  queue
//
//  Created by Andrew Sliwinski on 6/29/12.
//  Copyright (c) 2012 Andrew Sliwinski. All rights reserved.
//

#import <Foundation/Foundation.h>

//

typedef enum {
    EDQueueResultSuccess,
    EDQueueResultFail,
    EDQueueResultCritical
} EDQueueResult;

UIKIT_EXTERN NSString *const EDQueueDidStart;
UIKIT_EXTERN NSString *const EDQueueDidStop;
UIKIT_EXTERN NSString *const EDQueueJobDidSucceed;
UIKIT_EXTERN NSString *const EDQueueJobDidFail;
UIKIT_EXTERN NSString *const EDQueueDidDrain;

//

@class EDQueue;

@protocol EDQueueDelegate <NSObject>
@optional
- (EDQueueResult)queue:(EDQueue *)queue processJob:(NSDictionary *)job;
- (void)queue:(EDQueue *)queue processJob:(NSDictionary *)job completion:(void (^)(EDQueueResult result))block;
@end

//

@interface EDQueue : NSObject

@property (weak) id<EDQueueDelegate> delegate;
@property (readonly) Boolean isRunning;
@property (readonly) Boolean isActive;
@property NSUInteger retryLimit;

+ (EDQueue *)sharedInstance;
- (void)enqueueWithData:(id)data forTask:(NSString *)task;

- (void)start;
- (void)stop;
- (void)empty;

- (Boolean)jobExistsForTask:(NSString *)task;
- (Boolean)jobIsActiveForTask:(NSString *)task;
- (NSDictionary *)nextJobForTask:(NSString *)task;

@end
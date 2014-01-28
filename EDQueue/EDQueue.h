//
//  EDQueue.h
//  queue
//
//  Created by Andrew Sliwinski on 6/29/12.
//  Copyright (c) 2012 Andrew Sliwinski. All rights reserved.
//

#import <Foundation/Foundation.h>

//

typedef NS_ENUM(NSInteger, EDQueueResult) {
    EDQueueResultSuccess = 0,
    EDQueueResultFail,
    EDQueueResultCritical
};

extern NSString *const EDQueueDidStart;
extern NSString *const EDQueueDidStop;
extern NSString *const EDQueueJobDidSucceed;
extern NSString *const EDQueueJobDidFail;
extern NSString *const EDQueueDidDrain;

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
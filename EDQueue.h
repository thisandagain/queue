//
//  EDQueue.h
//  queue
//
//  Created by Andrew Sliwinski on 6/29/12.
//  Copyright (c) 2012 DIY, Co. All rights reserved.
//

#import <Foundation/Foundation.h>

//

#define DEFINE_SHARED_INSTANCE_USING_BLOCK(block) \
static dispatch_once_t pred = 0; \
__strong static id _sharedObject = nil; \
dispatch_once(&pred, ^{ \
_sharedObject = block(); \
}); \
return _sharedObject; \

typedef enum {
    kEDQueueResultSuccess,
    kEDQueueResultFail,
    kEDQueueResultCritical
} EDQueueResult;

//

@class EDQueue;

@protocol EDQueueDelegate <NSObject>
@required
- (EDQueueResult)queue:(EDQueue *)queue processJob:(NSDictionary *)job;
@end

//

@interface EDQueue : NSObject
{
    @private NSMutableArray *queue;
    @private NSTimer *timer;
    @private NSUInteger active;
}

@property (nonatomic, assign) id<EDQueueDelegate> delegate;
@property (nonatomic, assign) NSUInteger concurrencyLimit;
@property (nonatomic, assign) CGFloat statusInterval;
@property (nonatomic, assign) BOOL retryFailureImmediately;
@property (nonatomic, assign) NSUInteger retryLimit;

+ (EDQueue *)sharedInstance;
- (void)enqueueWithData:(id)data forTask:(NSString *)task;
- (void)start;
- (void)stop;

@end
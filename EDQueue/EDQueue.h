//
//  EDQueue.h
//  queue
//
//  Created by Andrew Sliwinski on 6/29/12.
//  Copyright (c) 2012 Andrew Sliwinski. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EDQueueStorageEngine.h"

//

#define DEFINE_SHARED_INSTANCE_USING_BLOCK(block) \
static dispatch_once_t pred = 0; \
__strong static id _sharedObject = nil; \
dispatch_once(&pred, ^{ \
_sharedObject = block(); \
}); \
return _sharedObject; \

typedef enum {
    EDQueueResultSuccess,
    EDQueueResultFail,
    EDQueueResultCritical
} EDQueueResult;

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

@end
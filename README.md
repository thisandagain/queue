## Queue
#### A persistent background job queue for iOS.

While `NSOperation` and `NSOperationQueue` work well for some repetitive problems and `NSInvocation` for others, iOS doesn't really include a set of tools for managing large collections of arbitrary background tasks easily. **EDQueue provides a high-level interface for implementing a threaded job queue using [GCD](http://developer.apple.com/library/ios/#documentation/Performance/Reference/GCD_libdispatch_Ref/Reference/reference.html) and [SQLLite3](http://www.sqlite.org/). All you need to do is handle the jobs within the provided delegate method and EDQueue handles the rest.**

### Getting Started
The easiest way to get going with EDQueue is to take a look at the included example application. The XCode project file can be found in `Project > queue.xcodeproj`.

### Setup
EDQueue needs both `libsqlite3.0.dylib` and [FMDB](https://github.com/ccgus/fmdb) for the storage engine. As always, the quickest way to take care of all those details is to use [CocoaPods](http://cocoapods.org/). EDQueue is implemented as a singleton as to allow jobs to be created from anywhere throughout an application. However, tasks are all processed through a single delegate method and thus it often makes the most sense to setup EDQueue within the application delegate:

YourAppDelegate.h
```objective-c
#import "EDQueue.h"
```
```objective-c
@interface YourAppDelegate : UIResponder <UIApplicationDelegate, EDQueueDelegate>
```

YourAppDelegate.m
```objective-c
- (void)applicationDidBecomeActive:(UIApplication *)application
{
    [[EDQueue sharedInstance] setDelegate:self];
    [[EDQueue sharedInstance] start];
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    [[EDQueue sharedInstance] stop];
}

- (EDQueueResult)queue:(EDQueue *)queue processJob:(NSDictionary *)job
{
    sleep(1);           // This won't block the main thread. Yay!
    
    // Wrap your job processing in a try-catch. Always use protection!
    @try {
        if ([[job objectForKey:@"task"] isEqualToString:@"success"]) {
            return EDQueueResultSuccess;
        } else if ([[job objectForKey:@"task"] isEqualToString:@"fail"]) {
            return EDQueueResultFail;
        }
    }
    @catch (NSException *exception) {
        return EDQueueResultCritical;
    }
    
    return EDQueueResultCritical;
}
```

SomewhereElse.m
```objective-c
[[EDQueue sharedInstance] enqueueWithData:@{ @"foo" : @"bar" } forTask:@"nyancat"];
```

In order to keep things simple, the delegate method expects a return type of `EDQueueResult` which permits three distinct states:
- `EDQueueResultSuccess`: Used to indicate that a job has completed successfully
- `EDQueueResultFail`: Used to indicate that a job has failed and should be retried (up to the specified `retryLimit`)
- `EDQueueResultCritical`: Used to indicate that a job has failed critically and should not be attempted again

### Handling Async Jobs
As of v0.6.0 queue includes a delegate method suited for handling asyncronous jobs such as HTTP requests or [Disk I/O](https://github.com/thisandagain/storage):

```objective-c
- (void)queue:(EDQueue *)queue processJob:(NSDictionary *)job completion:(void (^)(EDQueueResult))block
{
    sleep(1);
    
    @try {
        if ([[job objectForKey:@"task"] isEqualToString:@"success"]) {
            block(EDQueueResultSuccess);
        } else if ([[job objectForKey:@"task"] isEqualToString:@"fail"]) {
            block(EDQueueResultFail);
        } else {
            block(EDQueueResultCritical);
        }
    }
    @catch (NSException *exception) {
        block(EDQueueResultCritical);
    }
}
```

### Introspection
As of v0.7.0 queue includes a collection of methods to aid in queue introspection specific to each task:
```objective-c
- (Boolean)jobExistsForTask:(NSString *)task;
- (Boolean)jobIsActiveForTask:(NSString *)task;
- (NSDictionary *)nextJobForTask:(NSString *)task;
```

---

### Methods
```objective-c
- (void)enqueueWithData:(id)data forTask:(NSString *)task;

- (void)start;
- (void)stop;
- (void)empty;

- (Boolean)jobExistsForTask:(NSString *)task;
- (Boolean)jobIsActiveForTask:(NSString *)task;
- (NSDictionary *)nextJobForTask:(NSString *)task;
```

### Delegate Methods
```objective-c
- (EDQueueResult)queue:(EDQueue *)queue processJob:(NSDictionary *)job;
- (void)queue:(EDQueue *)queue processJob:(NSDictionary *)job completion:(void (^)(EDQueueResult result))block;
```

### Result Types
```objective-c
EDQueueResultSuccess
EDQueueResultFail
EDQueueResultCritical
```

### Properties
```objective-c
@property (weak) id<EDQueueDelegate> delegate;
@property (readonly) Boolean isRunning;
@property (readonly) Boolean isActive;
@property NSUInteger retryLimit;
```

### Notifications
```objective-c
EDQueueDidStart
EDQueueDidStop
EDQueueDidDrain
EDQueueJobDidSucceed
EDQueueJobDidFail
```

---

### iOS Support
EDQueue is designed for iOS 5 and up.

### ARC
EDQueue is built using ARC. If you are including EDQueue in a project that **does not** use [Automatic Reference Counting (ARC)](http://developer.apple.com/library/ios/#releasenotes/ObjectiveC/RN-TransitioningToARC/Introduction/Introduction.html), you will need to set the `-fobjc-arc` compiler flag on all of the EDQueue source files. To do this in Xcode, go to your active target and select the "Build Phases" tab. Now select all EDQueue source files, press Enter, insert `-fobjc-arc` and then "Done" to enable ARC for EDQueue.

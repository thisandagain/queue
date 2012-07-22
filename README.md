## Queue
#### A background job queue for iOS.

While `NSOperation` and `NSOperationQueue` work well for some repetitive problems and `NSInvocation` for others, iOS doesn't really include a set of tools for managing large collections of arbitrary background tasks easily. EDQueue provides a high-level interface for implementing a threaded job queue using [GCD](http://developer.apple.com/library/ios/#documentation/Performance/Reference/GCD_libdispatch_Ref/Reference/reference.html). All you need to do is handle the job within the provided delegate method and EDQueue handles the rest.

**EDQueue tries to provide three things:**
- A simple interface for handling background job queues across an application.
- A highly flexible and familiar convention for defining a generic task.
- Speed and safety.

## Getting Started
The easiest way to get going with EDQueue is to take a look at the included example application. The XCode project file can be found in `example > queue.xcodeproj`.

In order to include EDQueue in your project, you'll want to add the entirety of the `queue` directory to your project minus the example project. EDQueue is built on top of foundation libraries and so no additional frameworks are needed.

## Setup
EDQueue is implemented as a singleton as to allow jobs to be created from anywhere throughout an application. However, tasks are all processed through a single delegate method and thus it often makes the most sense to setup EDQueue within the application delegate:

YourAppDelegate.h
```objective-c
#import "EDQueue.h"
```
```objective-c
@interface YourAppDelegate : UIResponder <UIApplicationDelegate, EDQueueDelegate>
```

YourAppDelegate.m
```objective-c
[[EDQueue sharedInstance] setDelegate:self];
[[EDQueue sharedInstance] start];
```
```objective-c
- (EDQueueResult)queue:(EDQueue *)queue processJob:(NSDictionary *)job
{
    NSLog(@"Hey look it's a job! %@", job);
    return EDQueueResultSuccess;
}
```

SomewhereElse.m
```objective-c
[[EDQueue sharedInstance] enqueueWithData:kitty forTask:@"nyancat"];
```

In order to keep things simple, the delegate method expects a return type of `EDQueueResult` which permits three distinct states:
- `EDQueueResultSuccess`: Used to indicate that a job has completed successfully
- `EDQueueResultFail`: Used to indicate that a job has failed and should be retried (up to the specified `retryLimit`)
- `EDQueueResultCritical`: Used to indicate that a job has failed critically and should not be attempted again

---

## Methods
```objective-c
- (void)enqueueWithData:(id)data forTask:(NSString *)task;
- (void)start;
- (void)stop;
```

## Delegate Methods
```objective-c
- (EDQueueResult)queue:(EDQueue *)queue processJob:(NSDictionary *)job;
```

## Result Types
```objective-c
EDQueueResultSuccess
EDQueueResultFail
EDQueueResultCritical
```

## Properties
```objective-c
@property (nonatomic, assign) id<EDQueueDelegate> delegate;
@property (nonatomic, assign) NSUInteger concurrencyLimit;
@property (nonatomic, assign) CGFloat statusInterval;
@property (nonatomic, assign) BOOL retryFailureImmediately;
@property (nonatomic, assign) NSUInteger retryLimit;
```

## Notifications
```objective-c
EDQueueDidStart
EDQueueDidStop
EDQueueDidDrain
EDQueueJobDidSucceed
EDQueueJobDidFail
```

---

## Notes
EDQueue still has some additional features that I would like to add. Some of these will most certainly be implemented in the near future which may change the interface. I use [semver](http://semver.org/) versioning to help users know when to expect backward incompatible changes. If you have something that you would like to see included please create an issue or send along a pull request!

## iOS Support
EDQueue is tested on iOS 5 and up. Older versions of iOS may work but are not currently supported.

## ARC
If you are including EDQueue in a project that uses [Automatic Reference Counting (ARC)](http://developer.apple.com/library/ios/#releasenotes/ObjectiveC/RN-TransitioningToARC/Introduction/Introduction.html), you will need to set the `-fno-objc-arc` compiler flag on all of the EDQueue source files. To do this in Xcode, go to your active target and select the "Build Phases" tab. Now select all EDQueue source files, press Enter, insert `-fno-objc-arc` and then "Done" to disable ARC for EDQueue.

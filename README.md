## Queue
#### A background job queue for iOS.

In attempting to keep things [DRY](http://en.wikipedia.org/wiki/Don't_repeat_yourself), EDQueue was created to address the fair amount of boilerplate that often gets created to deal with writing data to disk within iOS applications in a performant manner. Disk I/O within iOS is synchronous and so much of this boilerplate is often written to improve performance by moving I/O to a background thread. EDQueue accomplishes this by transforming each write instance into a `NSOperation` which is managed by a single `NSOperationQueue`. All of this is done in the background while providing high-level methods to the user via categories. 

**EDQueue tries to provide three things:**
- A simple interface for handling background job queues across an application.
- A highly flexible and familiar convention for defining tasks.
- Speed and safety.

## Getting Started
The easiest way to get going with EDQueue is to take a look at the included example application. The XCode project file can be found in `example > queue.xcodeproj`.

In order to include EDQueue in your project, you'll want to add the entirety of the `queue` directory to your project minus the example project. EDQueue is built on top of foundation libraries and so no additional frameworks are needed.

## Setup
EDQueue is implemented as a singleton as to allow jobs to be created from anywhere throughout an application. However, tasks are all proceesed through a single delegate method and thus it often makes the most sense to setup EDQueue within the application delegate:

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

Each job that is added to EDQueue is handled within a background thread using [GCD](http://developer.apple.com/library/ios/#documentation/Performance/Reference/GCD_libdispatch_Ref/Reference/reference.html) and thus threading of jobs is handled for you. All you need to do is handle the job within the provided delegate method and EDQueue handles the rest. In order to keep things simple, the delegate method expects a return type of `EDQueueResult` which permits three distinct states:
- `EDQueueResultSuccess`: Used to indicate that a job has completed successfully
- `EDQueueResultFail`: Used to indicate that a job has failed and should be retried (up to the specified `retryLimit`)
- `EDQueueResultCritical`: Used to indicate that a job has failed critically and the queue should be stopped

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
EDQueue still has some additional features that I would like to add. Some of these will most certainly be implemented in the near future which may change the interface. I use [semver](http://semver.org/) versioning to help users know when to expect backward incompatable changes. If you have something that you would like to see included please create an issue or send along a pull request!

## iOS Support
EDQueue is tested on iOS 5 and up. Older versions of iOS may work but are not currently supported.

## ARC
If you are including EDQueue in a project that uses [Automatic Reference Counting (ARC)](http://developer.apple.com/library/ios/#releasenotes/ObjectiveC/RN-TransitioningToARC/Introduction/Introduction.html), you will need to set the `-fno-objc-arc` compiler flag on all of the EDQueue source files. To do this in Xcode, go to your active target and select the "Build Phases" tab. Now select all EDQueue source files, press Enter, insert `-fno-objc-arc` and then "Done" to disable ARC for EDQueue.

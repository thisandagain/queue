## Queue
#### A persistent background job queue for iOS.

While `NSOperation` and `NSOperationQueue` work well for some repetitive problems and `NSInvocation` for others, iOS doesn't really include a set of tools for managing large collections of arbitrary background tasks easily. EDQueue provides a high-level interface for implementing a threaded job queue using [GCD](http://developer.apple.com/library/ios/#documentation/Performance/Reference/GCD_libdispatch_Ref/Reference/reference.html) and [SQLLite3](http://www.sqlite.org/). All you need to do is handle the jobs within the provided delegate method and EDQueue handles the rest.

**EDQueue tries to provide three things:**
- A simple interface for handling background job queues across an application.
- Job queue persistence between application sessions.
- A highly flexible and familiar convention for defining a generic task.
- Speed and safety.

### Getting Started
The easiest way to get going with EDQueue is to take a look at the included example application. The XCode project file can be found in `example > queue.xcodeproj`.

In order to include EDQueue in your project, you'll want to add the entirety of the `queue` directory to your project minus the example project. EDQueue is built on top of foundation libraries and so no additional frameworks are needed.

### Setup
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

### Methods
```objective-c
- (void)enqueueWithData:(id)data forTask:(NSString *)task;
- (void)start;
- (void)stop;
```

### Delegate Methods
```objective-c
- (EDQueueResult)queue:(EDQueue *)queue processJob:(NSDictionary *)job;
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
EDQueue as of `v0.5.0` is built using ARC. If you are including EDQueue in a project that **does not** use [Automatic Reference Counting (ARC)](http://developer.apple.com/library/ios/#releasenotes/ObjectiveC/RN-TransitioningToARC/Introduction/Introduction.html), you will need to set the `-fobjc-arc` compiler flag on all of the EDQueue source files. To do this in Xcode, go to your active target and select the "Build Phases" tab. Now select all EDQueue source files, press Enter, insert `-fobjc-arc` and then "Done" to enable ARC for EDQueue.

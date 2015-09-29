//
//  TileRenderQueue.m
//  SheetSetter
//
//  Created by Pattrick Kreutzer on 09.03.11.
//  Copyright 2011 wysiwyg* software design gmbh.
//

#import "TileRenderQueue.h"

#import "TileRenderJob.h"


@implementation TileRenderQueue

- (id) init {
	if ((self = [super init])) {
		queueLock = [[NSCondition alloc] init];
		
		queue = [[NSMutableArray alloc] init];
		
		workerThread = [[NSThread alloc]
			initWithTarget: self
			selector: @selector (startThread:)
			object: nil];
		
		[workerThread start];
		
	}
	return self;
	
}

- (void) startThread: (id) info {
	BOOL done = NO;
	
	workerThreadRunLoop = [NSRunLoop currentRunLoop];
	
	do {
		NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
		
		[queueLock lock];
		if (![queue count])
			[queueLock wait];
		[queueLock unlock];
		
		if ([workerThread isCancelled])
			break;
		
        SInt32 result = CFRunLoopRunInMode (kCFRunLoopDefaultMode, 0, NO);
		
        if (result == kCFRunLoopRunStopped ||
			// result == kCFRunLoopRunFinished ||
			[workerThread isCancelled])
            done = YES;
		
		[pool release];
		
    } while (!done);
	
	[procTimer invalidate];
	
}

- (void) flushQueue {
	
	[queueLock lock]; {
		[procTimer invalidate];
		procTimer = nil;
		
		while (currentJob.state == STATE_BUSY) { // should not pass here
			NSLog (@"*** WARNING CURRENT JOB IS BUSY ***");
			[NSThread sleepForTimeInterval: 1. / 60.];
			
		}
		
		[queue removeAllObjects];
		
	} [queueLock unlock];
	
}

- (void) pauseQueue {
	
	[queueLock lock]; {
		[procTimer invalidate];
		procTimer = nil;
		
		[pausedQueue release];
		pausedQueue = [NSMutableArray new];
		
		NSMutableArray* queue_ = [queue copy];
		for (NSUInteger i = [queue_ count]; i--;) {
			TileRenderJob* job = [queue_ objectAtIndex: i];
			if (!job -> doNotUpdateLayerVisibility) {
				[pausedQueue addObject: job];
				[queue removeObject: job];
				
			}
			
		}
		[queue_ release];
		
//		pausedQueue = [queue copy];
//		[queue removeAllObjects];
		
	} [queueLock unlock];
	
}

- (void) unpauseQueue {
	
	if ([pausedQueue count]) {
		[self addToQueue: pausedQueue];
		pausedQueue = [NSMutableArray new];
	
	}
	
}

- (void) addToQueue: (NSArray*) jobs {
	[queueLock lock]; {
		[queue addObjectsFromArray: jobs];
		
		procTimer = [NSTimer timerWithTimeInterval: 1. / 60
			target: self selector: @selector (processQueue:)
			userInfo: nil repeats: YES
			
		];
		
		while (!workerThreadRunLoop)
			[NSThread sleepForTimeInterval: 1. / 60.];
		
		[workerThreadRunLoop addTimer: procTimer forMode: NSDefaultRunLoopMode];
		[workerThreadRunLoop addTimer: procTimer forMode: NSRunLoopCommonModes];
		
		[queueLock signal];
		
	} [queueLock unlock];
	
}

- (void) removeFromQueue: (TileRenderJob*) job {
	[queueLock lock];
	[queue removeObject: job];
	[queueLock unlock];
	
}

NSInteger tileRenderQueueSortFunction (TileRenderJob* a, TileRenderJob* b, void* context) {
	// NSLog (@"compare %@ to %@ (%f to %f)", a, b, a -> priority, b -> priority);
	return
	a .priority > b.priority ? NSOrderedAscending :
	NSOrderedDescending;
	
};

- (void) processQueue: (NSTimer*) timer {
	// NSLog (@"deferred process queue");
	[queueLock lock]; {
		
		/*
		NSLog (@"render queue center %f, %f",
			renderQueueCenter.x, renderQueueCenter.y);
		*/
		[queue sortUsingFunction: tileRenderQueueSortFunction context: nil];
		
		if ([queue count]) {
			currentJob = [queue objectAtIndex: 0];
			[currentJob retain];
			[queue removeObjectAtIndex: 0];
			
			if (![queue count])
				NSLog (@"tile queue rendered.");
			
		} else {
			[procTimer invalidate]; // does not pass here
			procTimer = nil;
			NSLog (@"queue rendered.");
			
		}
		
		if (currentJob) {
			[currentJob startProcess];
			[currentJob release];
			currentJob = nil;
			
		}
		
	} [queueLock unlock];
	
	
}

- (void) dealloc {
	
	[workerThread cancel];
	while (![workerThread isFinished])
		[NSThread sleepForTimeInterval: 1. / 60.];
	
	[queueLock lock]; {
		[queue release];
		
	} [queueLock unlock];
	
	[pausedQueue release];
	[queueLock release];
	
	[super dealloc];
	
}


@end

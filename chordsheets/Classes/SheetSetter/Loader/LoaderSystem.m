//
//  LoaderSystem.m
//  LoaderSystem
//
//  Created by Pattrick Kreutzer on 24.09.09.
//  Copyright 2009 wysiwyg* software gmbh. All rights reserved.
//

#import "LoaderSystem.h"


@interface LoaderSystem (Private)

- (void) cancelJob: (LoaderJob*) job;
- (void) processQueue;
- (void) _processQueue;

@end


@implementation LoaderSystem

- (id) init {
	self = [super init];
	
	if (self) {
		queue = [[NSMutableArray alloc] init];
		queueMap = [[NSMutableDictionary alloc] init];
		
		cache = [LoaderCache sharedInstance];
		
	}
	return self;

}


+ (LoaderSystem*) sharedInstance {
	static LoaderSystem* instance;
	if (!instance)
		instance = [[LoaderSystem alloc] init];
	
	return instance;

}

- (id) loaderForPath: (NSString*) path ofClass: (Class) class {
	id job = [cache cachedJobForPath: path];
	
	if (!job) {
		job = [[[class alloc] initWithPath: path] autorelease];
		// NSLog (@"... created %@", job);
		[cache storeJob: job];
		
	} else {
		// NSLog (@"... recycling %@", job);
		
	}
	return job;
	
}

- (void) enqueueJob: (LoaderJob*) job {

	NSString* keyPath = job -> path;
	
	if (job -> state == STATE_DONE) {
		// NSLog (@"warning. will not enqueue processed job. path is: %@", keyPath);
		[job dispatchEvent: @"complete"];
		
	} else {
		// NSLog (@"enqueueing job: %@", job);
		
		if ([queueMap valueForKey: keyPath]) {
			// NSLog (@"warning: concurrent access to key path: %@", keyPath);
			// [queue addObject: job]; // until cache available
			
		} else {
			[queue addObject: job];
			[queueMap setValue: job forKey: keyPath];
			
			[self processQueue];
			
		}
		
	}
	
}


- (void) processQueue {
	// [self _processQueue];
	// return;
	
	if (!procTimer) {
		procTimer = [NSTimer scheduledTimerWithTimeInterval: 1. / 6. // 60.
			target: self selector: @selector (deferredProcessQueue:)
			userInfo: nil repeats: NO
			
		];
		[procTimer retain];
		
	}
	
}

- (void) deferredProcessQueue: (NSTimer*) timer {
	// NSLog (@"tick");

	[procTimer invalidate];
	[procTimer release];
	procTimer = nil;
	
	[self _processQueue];
	
}

NSInteger compareLoaderJob (LoaderJob* a, LoaderJob* b, void* context) {
    // NSLog (@"compare %@ to %@ (%f to %f)", a, b, a -> priority, b -> priority);
    return
    a -> priority > b -> priority ? NSOrderedAscending :
    a -> priority == b -> priority ? (
                                      a -> state > b -> state ? NSOrderedAscending :
                                      a -> state == b -> state ? NSOrderedSame :
                                      NSOrderedDescending
                                      
                                      ) :
    NSOrderedDescending;
    
}

- (void) _processQueue {
	
	if (numCurrentJobs > MAX_NUM_CONCURRENT_JOBS) // optional
		NSLog (@"warning: max num concurrent jobs exceeded. (%i/%i)", numCurrentJobs, (int) MAX_NUM_CONCURRENT_JOBS);
	
/*
	NSLog (@"\n----");
	NSLog (@"num concurrent jobs %i", (int) numCurrentJobs);
	NSLog (@"num jobs in queue %i", (int) [queue count]);
	 NSLog (@"***** %@", queue);
	NSLog (@"----");
*/	

/*	
	for (int i = [queue count]; i--;) {
		LoaderJob* job = [queue objectAtIndex: i];
		
		(id) priorityClosure: Object = job.priorityClosure;
		if (priorityClosure)
			job.priority = priorityClosure ();

	}

*/		
/*
	int sortFunction (LoaderJob* a, LoaderJob* b, void* context) {
		// NSLog (@"compare %@ to %@ (%f to %f)", a, b, a -> priority, b -> priority);
		return
			a -> priority > b -> priority ? NSOrderedAscending :
			a -> priority == b -> priority ? (
				a -> state > b -> state ? NSOrderedAscending :
				a -> state == b -> state ? NSOrderedSame :
				NSOrderedDescending
				
			) :
			NSOrderedDescending;
			
	}*/

	[queue sortUsingFunction:compareLoaderJob context:nil];
		
	for (int i = 0; i < [queue count] && i < MAX_NUM_CONCURRENT_JOBS; i++) {
		LoaderJob* job = [queue objectAtIndex: i];
		if (!job -> state) {
			[job addListener: self selector: @selector (finishJob:) forEvent: @"complete"];
			[job addListener: self selector: @selector (finishJob:) forEvent: @"ioError"];
			
			[job load];
			numCurrentJobs++;
			
		}
		
	}
	
	for (int i = MAX_NUM_CONCURRENT_JOBS; i < [queue count]; i++) {
		LoaderJob* job = [queue objectAtIndex: i];
		[self cancelJob: job];
		
	}
	
}

- (void) flushQueue {
	while ([queue count])
		[self _processQueue];

}

- (void) cancelJob: (LoaderJob*) job {
	if (job -> state)
		numCurrentJobs--;

	[job removeListener: self selector: @selector (finishJob:) forEvent: @"complete"];
	[job removeListener: self selector: @selector (finishJob:) forEvent: @"ioError"];
	if (job -> state == STATE_BUSY)
		[job cancel];
	
}

- (void) finishJob: (LoaderJob*) job {
	[self removeJob: job];
	
	if (measureProgress) { 
		measureCurrentQueueLength--;
		
		// NSLog (@"--- ----- continue measure num jobs in queue: %i", measureCurrentQueueLength);

		[self dispatchEvent: @"progress"];
		
	}
	
}

- (void) removeJob: (LoaderJob*) job {
	[queueMap removeObjectForKey: job -> path];
	
	for (int i = (int) [queue count]; i--;) {
		if ([queue objectAtIndex: i] == job) {
			[self cancelJob: job];
			[queue removeObjectAtIndex: i];
			
		}
		
	}
	[self processQueue];

}

//

- (void) setMeasureProgress: (BOOL) flag {
	self -> measureProgress = flag;
	
	mearureStartQueueLength = measureCurrentQueueLength = (int) [queue count];
	if (!mearureStartQueueLength)
		mearureStartQueueLength = 1;

	// NSLog (@"----- start measure num jobs in queue: %i", measureCurrentQueueLength);
	
	if (flag)
		[self dispatchEvent: @"progress"];
	
}

- (float) currentProgress {
	float percentage = (float) measureCurrentQueueLength / mearureStartQueueLength;
	
	return 1 - percentage;
	
}

//

- (void) dealloc {
	if (procTimer) {
		[procTimer invalidate];
		[procTimer release];
		
	}
	
	[queue release];
	[queueMap release];
	
	[super dealloc];
	
}


@end

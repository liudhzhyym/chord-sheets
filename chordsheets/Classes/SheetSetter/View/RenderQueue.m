//
//  RenderQueue.m
//  SheetSetter
//
//  Created by Pattrick Kreutzer on 12.11.10.
//  Copyright 2010 wysiwyg* software design gmbh.
//

#import "RenderQueue.h"

#import "ScalableLayer.h"


#define DEBUG_RENDERING NO


CGPoint renderQueueCenter;


@interface RenderQueue (Private)

- (void) processQueue;
- (void) _processQueue;

@end


@implementation RenderQueue

- (id) init {
	if ((self = [super init])) {
		queue = [[NSMutableArray alloc] init];
		
	}
	return self;
	
}

- (void) flushQueue {
	for (ScalableLayer* layer in queue)
		layer.isInRenderQueue = false;
	
	[queue removeAllObjects];
	
}

- (void) addToQueue: (ScalableLayer*) layer {
	if (layer.isInRenderQueue)
		return;
	
	layer.isInRenderQueue = YES;
	[queue addObject: layer];
	
	if ([queue count] == 1)
		[self processQueue];
	
}

- (void) removeFromQueue: (ScalableLayer*) layer {
	if (!layer.isInRenderQueue)
		return;
	
	layer.isInRenderQueue = NO;
	[queue removeObject: layer];
	
}

- (void) processQueue {
	// [self _processQueue];
	// return;
	
	if (!procTimer) {
		procTimer = [NSTimer timerWithTimeInterval: DEBUG_RENDERING ? 1. / 1 : 1. / 60
			target: self selector: @selector (deferredProcessQueue:)
			userInfo: nil repeats: NO
			
		];
		
		NSRunLoop* runLoop = [NSRunLoop currentRunLoop];
		[runLoop addTimer: procTimer forMode: NSDefaultRunLoopMode];
		[runLoop addTimer: procTimer forMode: NSRunLoopCommonModes];
		
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

extern BOOL isDragging, isZooming, isAnimating;

NSInteger renderQueueSortFunction (ScalableLayer* a, ScalableLayer* b, void* context) {
	// NSLog (@"compare %@ to %@ (%f to %f)", a, b, a -> priority, b -> priority);
	return
	a .priority > b.priority ? NSOrderedAscending :
	NSOrderedDescending;
	
}

- (void) _processQueue {
	
/*
	NSLog (@"\n---- %@", self);
	NSLog (@"num jobs in queue %i", (int) [queue count]);
	// NSLog (@"***** %@", queue);
	NSLog (@"----");
*/
	
	if (isDragging || isZooming || isAnimating) {
		if ([queue count])
			[self processQueue];
		return;
		
	}
	
	/*
	NSLog (@"render queue center %f, %f",
		renderQueueCenter.x, renderQueueCenter.y);
	*/
	
	
	int renderingsPerPass = DEBUG_RENDERING ? 1 : 20; // 15 * 1;
	
	if ([queue count] > renderingsPerPass)
		[queue sortUsingFunction: renderQueueSortFunction context: nil];
	
	while (renderingsPerPass-- && [queue count]) {
		ScalableLayer* layer = [queue objectAtIndex: 0];
		
		// NSLog (@"rendering %@", layer);
		
		[layer setNeedsDisplay];
		[layer setNeedsRendering: NO];
		
		[queue removeObjectAtIndex: 0];
		layer.isInRenderQueue = NO;
		
	}
	
	if ([queue count])
		[self processQueue];
		
	else {
		// NSLog (@"queue rendered.");
		[self dispatchEvent: @"queueRendered"];
		
	}
	
}

- (void) dealloc {
	if (queue)
		[queue release];
	
	[procTimer invalidate];
	[procTimer release];
	procTimer = nil;
	
	[super dealloc];
	
}

@end

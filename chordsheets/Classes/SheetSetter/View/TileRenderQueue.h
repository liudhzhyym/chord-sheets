//
//  TileRenderQueue.h
//  SheetSetter
//
//  Created by Pattrick Kreutzer on 09.03.11.
//  Copyright 2011 wysiwyg* software design gmbh.
//

#import <Foundation/Foundation.h>


@class TileRenderJob;


@interface TileRenderQueue : NSObject {
	
	@protected
	
	NSMutableArray* queue;
	NSMutableArray* pausedQueue;
	
	NSCondition* queueLock;
	
	TileRenderJob* currentJob;
	
	NSThread* workerThread;
	NSRunLoop* workerThreadRunLoop;
	NSTimer* procTimer;
	
	
}

- (void) addToQueue: (NSArray*) jobs;
NSInteger tileRenderQueueSortFunction (TileRenderJob* a, TileRenderJob* b, void* context);
- (void) removeFromQueue: (TileRenderJob*) job;

- (void) pauseQueue;
- (void) unpauseQueue;

- (void) flushQueue;

@end

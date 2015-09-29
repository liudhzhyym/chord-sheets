//
//  RenderQueue.h
//  SheetSetter
//
//  Created by Pattrick Kreutzer on 12.11.10.
//  Copyright 2010 wysiwyg* software design gmbh.
//

#import <Foundation/Foundation.h>

#import "Dispatcher.h"


extern CGPoint renderQueueCenter;


@class ScalableLayer;


@interface RenderQueue : Dispatcher {
	
	@protected
	
	NSMutableArray* queue;
	
	NSTimer* procTimer;
	
	
}

- (void) flushQueue;

- (void) addToQueue: (ScalableLayer*) layer;
- (void) removeFromQueue: (ScalableLayer*) layer;

NSInteger renderQueueSortFunction (ScalableLayer* a, ScalableLayer* b, void* context);


@end

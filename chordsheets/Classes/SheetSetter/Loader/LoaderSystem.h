//
//  LoaderSystem.h
//  LoaderSystem
//
//  Created by Pattrick Kreutzer on 24.09.09.
//  Copyright 2009 wysiwyg* software design gmbh.
//

#import <UIKit/UIKit.h>

#import "Dispatcher.h"
#import "LoaderJob.h"

#import "LoaderCache.h"


#define MAX_NUM_CONCURRENT_JOBS 1


@interface LoaderSystem : Dispatcher {
	
	@protected

	NSMutableArray* queue;
	NSMutableDictionary* queueMap;
	
	int numCurrentJobs;
	
	NSTimer* procTimer;
	
	//
	
	LoaderCache* cache;
	
	//
	
	BOOL measureProgress;
	
	int mearureStartQueueLength;
	int measureCurrentQueueLength;
}

//

+ (LoaderSystem*) sharedInstance;

//

- (id) loaderForPath: (NSString*) path ofClass: (Class) class_;

NSInteger compareLoaderJob (LoaderJob* a, LoaderJob* b, void* context);

- (void) enqueueJob: (LoaderJob*) job;

- (void) removeJob: (LoaderJob*) job;

- (void) flushQueue;

//

- (void) setMeasureProgress: (BOOL) flag;

- (float) currentProgress;


@end

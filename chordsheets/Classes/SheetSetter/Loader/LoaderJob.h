//
//  LoaderJob.h
//  LoaderSystem
//
//  Created by Pattrick Kreutzer on 24.09.09.
//  Copyright 2009 wysiwyg* software design gmbh.
//

#import <UIKit/UIKit.h>

#import "Dispatcher.h"


typedef enum LoaderState {
	STATE_IDLE,
	STATE_BUSY,
	STATE_DONE

} LoaderState;


@interface LoaderJob : Dispatcher {

@public
	LoaderState state;
	
	BOOL useCache;
	BOOL lockInCache;
	
	NSString* path;
	void* data;
	
	float priority;	
	
}

- (id) initWithPath: (NSString*) path;

- (void) load;

- (void) cancel;


@end

//
//  LoaderJob.m
//  LoaderSystem
//
//  Created by Pattrick Kreutzer on 24.09.09.
//  Copyright 2009 wysiwyg* software design gmbh.
//

#import "LoaderJob.h"


@interface LoaderJob (Private)

- (void) complete;
- (void) ioError;

- (void) removeListeners;

@end


@implementation LoaderJob


- (id) initWithPath: (NSString*) path_ {
	self = [super init];
	
	if (self) {
		data = nil;
		self -> path = [path_ copy];
		
	}
	return self;
	
}

- (void) load {
	if (state)
		@throw [NSError
			errorWithDomain: [NSString stringWithFormat: @"cannot load %@ state is %i already.", self, state]
			code: 0 userInfo: nil];
	
	// NSLog (@"start loading %@.", self);
	state = STATE_BUSY;
	
}

- (void) cancel {
	if (state != STATE_BUSY)
		@throw [NSError
			errorWithDomain: [NSString stringWithFormat: @"cannot cancel %@ state is %i.", self, state]
			code: 0 userInfo: nil];
	
	NSLog (@"cancelling %@.", self);
	state = STATE_IDLE;
	
}

- (void) dealloc {
	// NSLog (@"deallocing %@.", self);
	[self dispatchEvent: @"destroy"];
	[path release];
	
	[super dealloc];
	
}

- (NSString*) description {
	return [NSString stringWithFormat: @"[LoaderJob %@ state: %i]", path, state];
	
}


@end

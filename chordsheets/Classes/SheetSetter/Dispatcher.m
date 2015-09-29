//
//  Dispatcher.m
//  LoaderSystem
//
//  Created by Pattrick Kreutzer on 24.09.09.
//  Copyright 2009 wysiwyg* software design gmbh.
//

#import "Dispatcher.h"


@interface ListenerTarget: NSObject {

@public	
	id listener;
	SEL	proc;
	
}

@end


@implementation ListenerTarget {

}

@end


@implementation Dispatcher


- (id) init {
	self = [super init];
	if (self) {
		registeredListeners = [[NSMutableDictionary alloc] init];
		
	}
	return self;
	
}

- (void) addListener: (id) listener selector: (SEL) proc forEvent: (NSString*) type {
	
	ListenerTarget* target = [[[ListenerTarget alloc] init] autorelease];
	target -> listener = listener;
	target -> proc = proc;
	
	NSMutableSet* targets =
		[registeredListeners objectForKey: type];
	
	if (targets) {

		NSEnumerator* targetsEnum = [targets objectEnumerator];
		ListenerTarget* target;
		
		while (target = [targetsEnum nextObject]) {
			id existingListener = target -> listener;
			SEL existingProc = target -> proc;
			
			if (listener == existingListener &&
				proc == existingProc)
				return;
			
		}
	
	} else {
		targets = [[[NSMutableSet alloc] init] autorelease];
		
		[registeredListeners setValue: targets forKey: type];
		
	}
	
	[targets addObject: target];
	
}

- (void) removeListener: (id) listener selector: (SEL) proc forEvent: (NSString*) type {
	NSMutableSet* targets =
		[registeredListeners objectForKey: type];
	
	if (targets) {
		NSEnumerator* targetsEnum = [targets objectEnumerator];
		ListenerTarget* target;
		
		while (target = [targetsEnum nextObject]) {
			id existingListener = target -> listener;
			SEL existingProc = target -> proc;
			
			if (listener == existingListener &&
				proc == existingProc) {
				[targets removeObject: target];
				break;
				
			}
			
		}
		if (![targets count]) {
			// NSLog (@"no more listeners for: %@", type);
			[registeredListeners removeObjectForKey: type];
		
		}
		
	}
	
}

- (void) dispatchEvent: (NSString*) type {
	// NSLog (@"will dispatch: %@", type);
	
	NSArray* targets = [[registeredListeners objectForKey: type] allObjects];
	
	if (targets) {
		// NSLog (@"targets: %@", targets);
		
		NSEnumerator* targetsEnum = [targets objectEnumerator];
		ListenerTarget* target;
		while (target = [targetsEnum nextObject]) {
			id listener = target -> listener;
			SEL proc = target -> proc;
			
			[listener performSelector: proc withObject: self];			
			
		}
		
	}
	// NSLog (@"did dispatch: %@", type);
	
}


- (void) dealloc {
	[registeredListeners release];
	
	[super dealloc];
	
}


@end

//
//  Dispatcher.h
//  LoaderSystem
//
//  Created by Pattrick Kreutzer on 24.09.09.
//  Copyright 2009 wysiwyg* software design gmbh.
//

#import <Foundation/Foundation.h>



@interface Dispatcher : NSObject {

@private
	NSMutableDictionary* registeredListeners;
	
}


- (void) addListener: (id) listener selector: (SEL) proc forEvent: (NSString*) type;
- (void) removeListener: (id) listener selector: (SEL) proc forEvent: (NSString*) type;

- (void) dispatchEvent: (NSString*) type;


@end

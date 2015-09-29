//
//  NSInvocationExtension.m
//  ParserContext
//
//  Created by Pattrick Kreutzer on 09.06.10.
//  Copyright 2010 wysiwyg* software design gmbh.
//

#import "Invocation.h"


@implementation Invocation

- initWithTarget: (id) _target selector: (SEL) _selector context: (id) _context {
	if ((self = [super init])) {
		target = _target;
		selector = _selector;
		context = _context;
		
	}
	return self;
	
}

- (void) invoke {
	[target performSelector: selector withObject: context];
	
}

@end

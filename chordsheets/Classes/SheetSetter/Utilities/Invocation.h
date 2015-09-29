//
//  NSInvocationExtension.h
//  ParserContext
//
//  Created by Pattrick Kreutzer on 09.06.10.
//  Copyright 2010 wysiwyg* software design gmbh.
//

#import <Foundation/Foundation.h>


@interface Invocation : NSObject {
	
	id target;
	SEL selector;
	id context;
	
}

- (id) initWithTarget: (id) target selector: (SEL) selector context: (id) context;

- (void) invoke;

@end

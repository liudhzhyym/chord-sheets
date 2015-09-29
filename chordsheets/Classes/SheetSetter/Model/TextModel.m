//
//  TextModel.m
//  SheetSetter
//
//  Created by Pattrick Kreutzer on 12.01.11.
//  Copyright 2011 wysiwyg* software design gmbh.
//

#import "TextModel.h"


@implementation TextModel


- (id) init {
    
	if ((self = [super init])) {
		
    }
    return self;
	
}

@synthesize label;
@synthesize text;
@synthesize isFirstElement;

- (NSString*) description {
	return [NSString stringWithFormat: @"<TextModel: (%@) %@>",
		label, text];
	
}

- (void) dealloc {
	[label release];
	[text release];
	
    [super dealloc];
	
}


@end

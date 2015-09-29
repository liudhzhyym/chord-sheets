//
//  ExtendedKeyLayer.m
//  Chord Sheets
//
//  Created by Pattrick Kreutzer on 11.04.12.
//  copyright (c) 2012 wysiwyg* software design gmbh.
//	Released into the public domain in 2015. http://creativecommons.org/publicdomain/zero/1.0/
//

#import "ExtendedKeyLayer.h"

#import "Key.h"


@implementation ExtendedKeyLayer

@synthesize keyExtension;


- (void) setModelObject: (Key*) key {
	
	[super setModelObject: key];
	
	if (key) {
		if (keyExtension == nil)
			self.text = [key stringValue];
		else
			self.text = [NSString stringWithFormat: @"%@%@",
				[key stringValue], keyExtension
				
			];
			
	} else
		self.text = @"";
	
}

- (void) dealloc {
	if (keyExtension)
		[keyExtension release];
	
	[super dealloc];
	
}

@end

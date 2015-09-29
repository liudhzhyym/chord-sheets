//
//  NSMutableString_XMLComposing.m
//  ChordPlayer
//
//  Created by Pattrick Kreutzer on 26.11.10.
//  Copyright 2010 wysiwyg* software design gmbh.
//

#import "NSMutableString_XMLComposing.h"

#import "NSString_XMLEscaping.h"


@implementation NSMutableString (XMLComposing)

- (void) appendXMLNodeWithName: (NSString*) name {
	[self appendString: [NSString stringWithFormat: @"<%@/>", name]];
	
}

- (void) appendXMLNodeWithName: (NSString*) name textContent: (NSString*) textContent {
	if ([textContent length])
		[self appendString: [NSString stringWithFormat: @"<%@>%@</%@>",
			name, [textContent stringByEscapingXML], name]
			
		];	
	else
		[self appendXMLNodeWithName: name];
	
}

- (void) appendXMLNodeWithName: (NSString*) name attributes: (NSDictionary*) attributes {
	
	[self appendString: [NSString stringWithFormat: @"<%@>", name]];
	
	for (NSString* key in [attributes allKeys]) {
		NSString* value = [attributes objectForKey: key];
		[self appendString: [NSString stringWithFormat: @" %@=\"%@\"",
			[key stringByEscapingXML], [value stringByEscapingXML]]];
		
	}	
	[self appendString: [NSString stringWithFormat: @"</%@>", name]];
	
}

@end

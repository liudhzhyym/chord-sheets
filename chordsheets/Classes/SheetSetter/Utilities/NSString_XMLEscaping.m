//
//  NSString_XMLEscaping.m
//  ChordPlayer
//
//  Created by Pattrick Kreutzer on 26.11.10.
//  Copyright 2010 wysiwyg* software design gmbh.
//

#import "NSString_XMLEscaping.h"


@implementation NSString (XMLEscaping)

- (NSString*) stringByEscapingXML {
	
	NSMutableString* buffer = [self mutableCopy];
	
	[buffer replaceOccurrencesOfString: @"&" withString: @"&amp;"
		options: NSLiteralSearch range: NSMakeRange (0, [buffer length])];
	[buffer replaceOccurrencesOfString: @"<" withString: @"&lt;"
		options: NSLiteralSearch range: NSMakeRange (0, [buffer length])];
	[buffer replaceOccurrencesOfString: @">" withString: @"&gt;"
		options: NSLiteralSearch range: NSMakeRange (0, [buffer length])];
	[buffer replaceOccurrencesOfString: @"\"" withString: @"&quot;"
		options: NSLiteralSearch range: NSMakeRange (0, [buffer length])];
	[buffer replaceOccurrencesOfString: @"'" withString: @"&#x27;"
		options: NSLiteralSearch range: NSMakeRange (0, [buffer length])];
	
	return [buffer autorelease];
	
}

@end

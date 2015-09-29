//
//  AttributedKey.m
//  ChordPlayer
//
//  Created by Pattrick Kreutzer on 26.11.10.
//  Copyright 2010 wysiwyg* software design gmbh.
//

#import "AttributedChord.h"

#import "NSMutableString_XMLComposing.h"


@implementation AttributedChord

// construction

- (id) initWithCoder: (NSCoder*) coder {
	if (self = [super initWithCoder: coder]) {
		annotation = [[coder decodeObjectForKey: @"annotation"] retain];
		isSyncopic = (BOOL) [coder decodeIntForKey: @"isSyncopic"];
		
	}
	return self;
	
}

- (id) copyWithZone: (NSZone*) zone {
	AttributedChord* instance = [super copyWithZone: zone];
	
	instance.annotation = self.annotation;
	instance.isSyncopic = self.isSyncopic;
	
	return instance;
	
}

// properties

- (void) setKey: (Key*) _key {
	if (key == _key)
		return;
	
	[super setKey: _key];
	if (!key) {
		self.isSyncopic = NO;
		
	}
	
}

- (NSString*) annotation {
	return annotation;
	
}

- (void) setAnnotation: (NSString*) _annotation {
	if (annotation == _annotation)
		return;
	
	[annotation release];
	annotation = [_annotation retain];
	
}

- (BOOL) isSyncopic {
	return isSyncopic;
	
}

- (void) setIsSyncopic: (BOOL) _isSyncopic {
	isSyncopic = _isSyncopic;
	
}

- (BOOL) isEmpty {
	return [super isEmpty] && !annotation;
	
}

// serialization

- (NSString*) toXMLString {
	NSMutableString* buffer = [NSMutableString string];
	
	if (isSyncopic)
		[buffer appendXMLNodeWithName: @"syncopation"];
	
	if (key)
		[buffer appendString: [key stringValue]];
	
	[buffer appendString: [self chordOptionsSerialString]];
	
	if (bassKey) {
		[buffer appendString: @"/"];
		[buffer appendString: [bassKey stringValue]];
		
	}
	
	if (annotation)
		[buffer appendXMLNodeWithName: @"annotation" textContent: annotation];
	
	return buffer;
	
}

- (void) encodeWithCoder: (NSCoder*) coder {
	[super encodeWithCoder: coder];
	
	[coder encodeInt: isSyncopic forKey: @"isSyncopic"];
	[coder encodeObject: annotation forKey: @"annotation"];
	
}

// deallocation

- (void) dealloc {
	if (annotation)
		[annotation release];
	
	[super dealloc];
	
}

@end

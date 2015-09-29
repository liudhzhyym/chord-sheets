//
//  Key.m
//  ChordPlayer
//
//  Created by Pattrick Kreutzer on 26.11.10.
//  Copyright 2010 wysiwyg* software design gmbh.
//

#import "Key.h"

#import "KeySignature.h"


@implementation Key

// class initalization

static NSDictionary* keySymbolTable;
static NSArray* genericSymbolTable;

+ (void) initialize {
	keySymbolTable = [[NSDictionary alloc] initWithObjectsAndKeys:
		[NSNumber numberWithInt: 11], @"Cb",
		[NSNumber numberWithInt: 0], @"C",
		[NSNumber numberWithInt: 1], @"C#",
		[NSNumber numberWithInt: 1], @"Db",
		[NSNumber numberWithInt: 2], @"D",
		[NSNumber numberWithInt: 3], @"D#",
		[NSNumber numberWithInt: 3], @"Eb",
		[NSNumber numberWithInt: 4], @"E",
		[NSNumber numberWithInt: 5], @"E#",
		[NSNumber numberWithInt: 4], @"Fb",
		[NSNumber numberWithInt: 5], @"F",
		[NSNumber numberWithInt: 6], @"F#",
		[NSNumber numberWithInt: 6], @"Gb",
		[NSNumber numberWithInt: 7], @"G",
		[NSNumber numberWithInt: 8], @"G#",
		[NSNumber numberWithInt: 8], @"Ab",
		[NSNumber numberWithInt: 9], @"A",
		[NSNumber numberWithInt: 10], @"A#",
		[NSNumber numberWithInt: 10], @"Bb",
		[NSNumber numberWithInt: 11], @"B",
		[NSNumber numberWithInt: 0], @"B#",
		[NSNumber numberWithInt: 10], @"Hb",
		[NSNumber numberWithInt: 11], @"H",
		[NSNumber numberWithInt: 0], @"H#",
		nil
		
	];
	
	genericSymbolTable = [[
		@"C C# D D# E F F# G G# A A# B"
		componentsSeparatedByString: @" "] retain];
	
}

// construction

+ (id) keyWithInt: (int) value {
	return [[[[self class] alloc] initWithInt: value] autorelease];
	
}

+ (id) keyWithString: (NSString*) value {
	return [[[[self class] alloc] initWithString: value] autorelease];
	
}

- (id) initWithInt: (int) value {
	if ((self = [super init])) {
		self.intValue = value;
		
	}
	return self;
	
}

- (id) initWithString: (NSString*) value {
	if ((self = [super init])) {
		[self setStringValue: value];
		
	}
	return self;
	
}

- (id) initWithCoder: (NSCoder*) coder {
	if (self = [self init]) {
		intValue = [coder decodeIntForKey: @"intValue"];
		
	}
	return self;
	
}

- (id) copyWithZone: (NSZone*) zone {
	Key* instance = [[[self class] allocWithZone: zone] init];
	
	instance -> intValue = intValue;
	if (stringValue)
		instance -> stringValue = [stringValue copy];
	
	return instance;
	
}

// properties

- (int) intValue {
	return intValue;
	
}

- (void) setIntValue: (int) value {
	intValue = value % 12;
	if (intValue < 0)
		intValue += 12;
	
	if (stringValue)
		[stringValue release];
	stringValue = nil;
	
}

- (NSString*) stringValueForKeySignature: (KeySignature*) keySignature {
	return [keySignature stringValueOfKey: self];
	
}

- (NSString*) stringValue {
	return stringValue ? stringValue :
		[genericSymbolTable objectAtIndex: intValue];
	
}

- (void) setStringValue: (NSString*) value {
	if (stringValue == value)
		return;
	
	[stringValue release];
	stringValue = [value retain];
	
	intValue = [[keySymbolTable objectForKey: value] intValue];
	
}

- (NSString*) description {
	return [NSString stringWithFormat: @"<Key %@, %i>",
		self.stringValue, self.intValue];
	
}

// serialization

- (void) encodeWithCoder: (NSCoder*) coder {
	[coder encodeInt: intValue forKey: @"intValue"];
	
}

// deallocation

- (void) dealloc {
	if (stringValue)
		[stringValue release];
	
	[super dealloc];
	
}

@end

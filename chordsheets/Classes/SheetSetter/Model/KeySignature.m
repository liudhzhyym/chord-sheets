//
//  KeySignature.m
//  ChordPlayer
//
//  Created by Pattrick Kreutzer on 26.11.10.
//  Copyright 2010 wysiwyg* software design gmbh.
//

#import "KeySignature.h"


@implementation KeySignature

// class initalization

static NSArray* majorKeyStrings;
static NSArray* minorKeyStrings;

static NSArray* keysFlatTable;
static NSArray* keysSharpTable;

+ (void) initialize {
	if (!majorKeyStrings) {
		majorKeyStrings = [[
			@"C:#, Db:b, D:#, Eb:b, E:#, F:#, Gb:b|F#:#, G:#, Ab:b, A:#, Bb:b, B:#"
			componentsSeparatedByString: @", "
			
		] retain];
		minorKeyStrings = [[
			@"C:b, C#:#, D:b, D#:#|Eb:b, E:#, F:b, F#:#, G:b, G#:#, A:b, Bb:b, B:#"
			componentsSeparatedByString: @", "
			
		] retain];

		keysFlatTable = [[
			@"C, Db, D, Eb, E, F, Gb, G, Ab, A, Bb, B"
			componentsSeparatedByString: @", "
			
		] retain];
		keysSharpTable = [[
			@"C, C#, D, D#, E, F, F#, G, G#, A, Bb, B"
			componentsSeparatedByString: @", "
			
		] retain];
		
	}
	
}

// construction

- (id) initWithKey: (Key*) _key isMinor: (BOOL) _isMinor {
	if (self = [self init]) {
		self.key = _key;
		self.isMinor = _isMinor;
		
	}
	return self;
	
}

- (id) initWithCoder: (NSCoder*) coder {
	if (self = [self init]) {
		self.key = [coder decodeObjectForKey: @"key"];
		self.isMinor = (BOOL) [coder decodeIntForKey: @"isMinor"];
		
	}
	return self;
	
}

- (id) copyWithZone: (NSZone*) zone {
	KeySignature* instance = [[[self class] allocWithZone: zone] init];
	
    Key *keyCopy = [[self key] copyWithZone:zone];
	instance.key = keyCopy;
    [keyCopy release];
	instance.isMinor = self.isMinor;
	
	return instance;
	
}

// properties

- (Key*) key {
	return key;
	
}

- (void) updateKeyString {
	int keyIntValue = key.intValue;
	NSString* keyStringValue = key.stringValue;
	
	NSArray* signatureKeyDefinitions =
		[[(isMinor ? minorKeyStrings : majorKeyStrings)
			objectAtIndex: keyIntValue] componentsSeparatedByString: @"|"];
	
	BOOL matchesDefinition = NO;
	NSString* signatureKeyString;
	for (NSString* signatureKeyDefinition in signatureKeyDefinitions) {
		signatureKeyString = [[signatureKeyDefinition componentsSeparatedByString: @":"] objectAtIndex: 0];
		if ([keyStringValue isEqualToString: signatureKeyString]) {
			matchesDefinition = YES;
			break;
			
		}
		
	}
	
	NSArray* definitionComponents = [[signatureKeyDefinitions objectAtIndex: 0]
		componentsSeparatedByString: @":"];
	
	if (!matchesDefinition)
		[key setStringValue: [definitionComponents objectAtIndex: 0]];
	
	if ([key.stringValue length] > 1)
		useFlatKeyTable =
			[key.stringValue characterAtIndex: 1] ==
				[@"b" characterAtIndex: 0];
	else
		useFlatKeyTable =
			[[definitionComponents objectAtIndex: 1] characterAtIndex: 0] ==
				[@"b" characterAtIndex: 0];
		
}

- (void) setKey: (Key*) _key {
	if (key == _key)
		return;
	
	[key release];
	key = [_key retain];
	
	[self updateKeyString];
	
}

- (BOOL) isMinor {
	return isMinor;
	
}

- (void) setIsMinor: (BOOL) _isMinor {
	isMinor = _isMinor;
	[self updateKeyString];
	
}

- (NSString*) stringValue {
	return [NSString stringWithFormat: (isMinor ? @"%@-" : @"%@"),
		key.stringValue];
	
}

- (NSString*) displayStringValue {
	return [NSString stringWithFormat: (isMinor ? @"%@m" : @"%@"),
		key.stringValue];
	
}

- (void) setStringValue: (NSString*) stringValue {
	NSArray* stringComp = [
		[stringValue stringByReplacingOccurrencesOfString: @"m" withString: @"-"]
			componentsSeparatedByString: @"-"];
	BOOL _isMinor = [stringComp count] > 1;
	
	Key* _key = [[Key alloc] initWithString: [stringComp objectAtIndex: 0]];
	self.key = _key;
	[_key release];
	
	[self setIsMinor: _isMinor];
	
}

- (NSString*) stringValueOfKey: (Key*) _key {
	int keyIntValue = _key.intValue;
	return [(useFlatKeyTable ? keysFlatTable : keysSharpTable)
		objectAtIndex: keyIntValue];
	
}

- (NSString*) description {
	return [NSString stringWithFormat: @"<KeySignature %@>",
		[self stringValue]];
	
}

// serialization

- (void) encodeWithCoder: (NSCoder*) coder {
	[coder encodeObject: key forKey: @"key"];
	[coder encodeInt: isMinor forKey: @"isMinor"];
	
}

- (NSString*) toXMLString {
	return [NSString stringWithFormat: @"<keysignature>%@</keysignature>",
		[self stringValue]];
	
}

// deallocation

- (void) dealloc {
	if (key)
		[key release];
	
	[super dealloc];
	
}

@end

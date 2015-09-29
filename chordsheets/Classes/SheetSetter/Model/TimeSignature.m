//
//  TimeSignature.m
//  ChordPlayer
//
//  Created by Pattrick Kreutzer on 26.11.10.
//  Copyright 2010 wysiwyg* software design gmbh.
//

#import "TimeSignature.h"


@implementation TimeSignature

// construction

- (id) initWithCoder: (NSCoder*) coder {
	if ((self = [super init])) {
		numerator = [coder decodeIntForKey: @"numerator"];
		denominator = [coder decodeIntForKey: @"denominator"];
		
	}
	return self;
	
}

- (id) copyWithZone: (NSZone*) zone {
	TimeSignature* instance = [[[self class] allocWithZone: zone] init];
	
	instance.numerator = self.numerator;
	instance.denominator = self.denominator;
	
	return instance;
	
}

// properties

- (int) numerator {
	return numerator;
	
}

- (void) setNumerator: (int) _numerator {
	numerator = _numerator;
	
}

- (int) denominator {
	return denominator;
	
}

- (void) setDenominator: (int) _denominator {
	denominator = _denominator;
	
}

- (int) chordCountForBar {
	if (numerator <= 5)
		return numerator;
	
	else {
		if (fmod (numerator / 7, 1.f) == 0.f)
			return 7;
		if (fmod (numerator / 3, 1.f) == 0.f)
			return 3;
		
	}
	return 4;
	
}

- (NSString*) stringValue {
	return [NSString
		stringWithFormat: @"%i/%i",
		numerator, denominator
		
	];
	
}

- (void) setStringValue: (NSString*) value {
	
	NSArray* components = [value componentsSeparatedByString: @"/"];
	numerator = [[components objectAtIndex: 0] intValue];
	denominator = [[components objectAtIndex: 1] intValue];
	
}

// serialization

- (NSString*) toXMLString {
	return [NSString stringWithFormat: @"<timesignature>%@</timesignature>",
		[self stringValue]];
	
}

- (void) encodeWithCoder: (NSCoder*) coder {
	[coder encodeInt: numerator forKey: @"numerator"];
	[coder encodeInt: denominator forKey: @"denominator"];
	
}

@end

//
//  BarLine.m
//  ChordPlayer
//
//  Created by Pattrick Kreutzer on 26.11.10.
//  Copyright 2010 wysiwyg* software design gmbh.
//

#import "BarLine.h"

#import "NSString_XMLEscaping.h"


NSString* BAR_LINE_TYPE_SINGLE = @"single";
NSString* BAR_LINE_TYPE_DOUBLE = @"double";

NSString* BAR_LINE_REHEARSAL_MARK_SEGNO = @"segno";
NSString* BAR_LINE_REHEARSAL_MARK_CODA = @"coda";
NSString* BAR_LINE_REHEARSAL_MARK_DA_CAPO = @"da_capo";
NSString* BAR_LINE_REHEARSAL_MARK_DAL_SEGNO = @"dal_segno";
NSString* BAR_LINE_REHEARSAL_MARK_FINE = @"fine";

NSString* BAR_LINE_REHEARSAL_LINE_WRAP = @"line_wrap";


@implementation BarLine

// construction

- (id) init {
	if ((self = [super init])) {
		rehearsalMarks = [[NSMutableSet alloc] init];
		// type = BAR_LINE_TYPE_SINGLE;
		
	}
	return self;
	
}

- (id) initWithCoder: (NSCoder*) coder {
	if (self = [self init]) {
		type = [[coder decodeObjectForKey: @"type"] retain];
		repeatCount = [coder decodeIntForKey: @"repeatCount"];
		
		if (rehearsalMarks)
			[rehearsalMarks release];
		rehearsalMarks = [[coder decodeObjectForKey: @"rehearsalMarks"] mutableCopy];
		
	}
	return self;
	
}

- (id) copyWithZone: (NSZone*) zone {
	BarLine* instance = [[[self class] allocWithZone: zone] init];
	
	instance.type = self.type;
	instance.repeatCount = self.repeatCount;
	
	if (instance -> rehearsalMarks)
		[instance -> rehearsalMarks release];
	instance -> rehearsalMarks = [self.rehearsalMarks mutableCopyWithZone: zone]; // needs deep copy
	
	return instance;
	
}

// properties

- (NSString*) type {
	return type ? type : BAR_LINE_TYPE_SINGLE;
	
}

- (void) setType: (NSString*) _type {
	if (type == _type)
		return;
	
	[type release];
	type = [_type retain];
	
}

- (int) repeatCount {
	return repeatCount;
	
}

- (void) setRepeatCount: (int) _repeatCount {
	repeatCount = _repeatCount;
	
}

- (void) addRehearsalMark: (NSString*) rehearsalMark {
	[rehearsalMarks addObject: rehearsalMark];
	
}

- (void) removeRehearsalMark: (NSString*) rehearsalMark {
	[rehearsalMarks removeObject: rehearsalMark];
	
}

- (void) removeAllRehearsalMarks {
	[rehearsalMarks removeAllObjects];
	
}

- (NSSet*) rehearsalMarks {
	return rehearsalMarks;
	
}

- (NSArray*) orderedRehearsalMarks {
	return [[rehearsalMarks allObjects] sortedArrayUsingComparator: ^NSComparisonResult (NSString* a, NSString* b) {
		return -[a compare: b];
		
	}];
	
}

// serialization

- (void) encodeWithCoder: (NSCoder*) coder {
	[coder encodeObject: type forKey: @"type"];
	[coder encodeInt: repeatCount forKey: @"repeatCount"];
	[coder encodeObject: rehearsalMarks forKey: @"rehearsalMarks"];
	
}

- (BOOL) isDefault {
	return (!type || [type isEqualToString: BAR_LINE_TYPE_SINGLE]) &&
		!repeatCount && ![rehearsalMarks count];
	
}

- (NSString*) toXMLString {
	return @"<barline/>";
	
}

- (NSString*) innerXMLString {
	NSMutableString* buffer = [NSMutableString string];
	
	for (NSString* rehearsalMark in [self orderedRehearsalMarks])
		[buffer appendString: [NSString stringWithFormat: @"<rehearsalmark class=\"%@\"/>",
			[rehearsalMark stringByEscapingXML]]];
	
	return buffer;
	
}

// deallocation

- (void) dealloc {
	if (type)
		[type release];
	if (rehearsalMarks)
		[rehearsalMarks release];
	
	[super dealloc];
	
}

@end

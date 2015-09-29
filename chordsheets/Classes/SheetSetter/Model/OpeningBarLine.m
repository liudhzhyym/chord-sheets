//
//  OpeningBarLine.m
//  ChordPlayer
//
//  Created by Pattrick Kreutzer on 26.11.10.
//  Copyright 2010 wysiwyg* software design gmbh.
//

#import "OpeningBarLine.h"

#import "NSString_XMLEscaping.h"
#import "NSMutableString_XMLComposing.h"


NSString* BAR_LINE_BAR_MARK_WHOLE_REST = @"whole_rest";
NSString* BAR_LINE_BAR_MARK_SIMILE = @"simile";
NSString* BAR_LINE_BAR_MARK_TWO_BAR_SIMILE = @"two_bar_simile";


@implementation OpeningBarLine

// construction

- (id) initWithCoder: (NSCoder*) coder {
	if (self = [super initWithCoder: coder]) {
		keySignature = [[coder decodeObjectForKey: @"keySignature"] retain];
		timeSignature = [[coder decodeObjectForKey: @"timeSignature"] retain];
		
		annotation = [[coder decodeObjectForKey: @"annotation"] retain];
		voltaCount = [coder decodeIntForKey: @"voltaCount"];
		barMark = [[coder decodeObjectForKey: @"barMark"] retain];
		
	}
	return self;
	
}

- (id) copyWithZone: (NSZone*) zone {
	OpeningBarLine* instance = [super copyWithZone: zone];

	if (keySignature)
		instance -> keySignature = [self.keySignature copyWithZone: zone];
	if (timeSignature)
		instance -> timeSignature = [self.timeSignature copyWithZone: zone];
		
	instance.annotation = self.annotation;
	instance.voltaCount = self.voltaCount;
	instance.barMark = self.barMark;
	
	return instance;
	
}

// properties

- (KeySignature*) keySignature {
	return keySignature;
	
}

- (void) setKeySignature: (KeySignature*) _keySignature {
	if (keySignature == _keySignature)
		return;
	
	[keySignature release];
	keySignature = [_keySignature retain];
	
}

- (TimeSignature*) timeSignature {
	return timeSignature;
	
}

- (void) setTimeSignature: (TimeSignature*) _timeSignature {
	if (timeSignature == _timeSignature)
		return;
	
	[timeSignature release];
	timeSignature = [_timeSignature retain];
	
}

- (NSString*) annotation {
	return annotation;
	
}

- (void) setAnnotation: (NSString*) _annotation {
	if (annotation == _annotation)
		return;
	
	[annotation release];
	annotation = [_annotation retain]; // serialization];
	
}

- (int) voltaCount {
	return voltaCount;
	
}

- (void) setVoltaCount: (int) _voltaCount {
	voltaCount = _voltaCount;
	
}

- (NSString*) barMark {
	return barMark;
	
}

- (void) setBarMark: (NSString*) _barMark {
	if (barMark == _barMark)
		return;
	
	[barMark release];
	barMark = [_barMark retain];
	
}

- (void) addRehearsalMark: (NSString*) rehearsalMark {
	[super addRehearsalMark: rehearsalMark];
	
	if ([rehearsalMark isEqualToString: BAR_LINE_REHEARSAL_MARK_SEGNO])
		[self removeRehearsalMark: BAR_LINE_REHEARSAL_MARK_CODA];
	
	if ([rehearsalMark isEqualToString: BAR_LINE_REHEARSAL_MARK_CODA])
		[self removeRehearsalMark: BAR_LINE_REHEARSAL_MARK_SEGNO];
	
}

- (BOOL) clearsBar {
	return [barMark isEqualToString: BAR_LINE_BAR_MARK_WHOLE_REST] ||
		[barMark isEqualToString: BAR_LINE_BAR_MARK_SIMILE] ||
		[barMark isEqualToString: BAR_LINE_BAR_MARK_TWO_BAR_SIMILE];
	
}

- (BOOL) clearsNextBar {
	return [barMark isEqualToString: BAR_LINE_BAR_MARK_TWO_BAR_SIMILE];
	
}

// serialization

- (BOOL) isDefault {
	return [super isDefault] && !annotation &&
		!keySignature && !timeSignature && !voltaCount && !barMark;
	
}

- (NSString*) innerXMLString {
	NSMutableString* buffer = [NSMutableString string];
	
	if (repeatCount || (type != nil && ![type isEqualToString: BAR_LINE_TYPE_SINGLE])) {
		[buffer appendString: @"<barline"];
		if (!(type == nil || [type isEqualToString: BAR_LINE_TYPE_SINGLE]))
			[buffer appendString: [NSString stringWithFormat: @" class=\"%@\"", type]];
		if (repeatCount)
			[buffer appendString: @" repeat=\"1\""];
		
		[buffer appendString: @"/>"];
		
	}
	[buffer appendString: [super innerXMLString]];
	
	if (voltaCount)
		[buffer appendString: [NSString stringWithFormat: @"<ending class=\"ending_%i\"/>", voltaCount]];
	
	if (annotation)
		[buffer appendXMLNodeWithName: @"annotation" textContent: annotation];
	
	if (barMark) {
		if ([barMark isEqualToString: BAR_LINE_BAR_MARK_WHOLE_REST])
			[buffer appendString: @"<pause/>"];
		else if ([barMark isEqualToString: BAR_LINE_BAR_MARK_SIMILE])
			[buffer appendString: @"<simile class=\"single\"/>"];
		else if ([barMark isEqualToString: BAR_LINE_BAR_MARK_TWO_BAR_SIMILE])
			[buffer appendString: @"<simile class=\"double\"/>"];
		
	}
	return buffer;
	
}

- (NSString*) toXMLString {
	NSMutableString* buffer = [NSMutableString string];
	
	[buffer appendString: @"<opening>"];
	
	if (keySignature)
		[buffer appendString: [keySignature toXMLString]];
	if (timeSignature)
		[buffer appendString: [timeSignature toXMLString]];
	
	[buffer appendString: [self innerXMLString]];
	
	[buffer appendString: @"</opening>"];
	
	return buffer;
	
}


- (void) encodeWithCoder: (NSCoder*) coder {
	[super encodeWithCoder: coder];
	
	[coder encodeObject: keySignature forKey: @"keySignature"];
	[coder encodeObject: timeSignature forKey: @"timeSignature"];
		
	[coder encodeObject: annotation forKey: @"annotation"];
	[coder encodeInt: voltaCount forKey: @"voltaCount"];
	[coder encodeObject: barMark forKey: @"barMark"];
	
}

// deallocation

- (void) dealloc {
	if (keySignature)
		[keySignature release];
	if (timeSignature)
		[timeSignature release];
	
	if (annotation)
		[annotation release];
	if (barMark)
		[barMark release];
	
	[super dealloc];
	
}


@end

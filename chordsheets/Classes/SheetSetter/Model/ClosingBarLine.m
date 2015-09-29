//
//  ClosingBarLine.m
//  ChordPlayer
//
//  Created by Pattrick Kreutzer on 26.11.10.
//  Copyright 2010 wysiwyg* software design gmbh.
//

#import "ClosingBarLine.h"


@implementation ClosingBarLine

// construction

- (id) initWithCoder: (NSCoder*) coder {
	if (self = [super initWithCoder: coder]) {
		self.wrapsAfterBar = (BOOL) [coder decodeIntForKey: @"wrapsAfterBar"];
		
	}
	return self;
	
}

// properties

- (BOOL) wrapsAfterBar {
	return [rehearsalMarks containsObject: BAR_LINE_REHEARSAL_LINE_WRAP];
	
}

- (void) setWrapsAfterBar: (BOOL) _wrapsAfterBar {
	if (_wrapsAfterBar)
		[self addRehearsalMark: BAR_LINE_REHEARSAL_LINE_WRAP];
	else
		[self removeRehearsalMark: BAR_LINE_REHEARSAL_LINE_WRAP];
	
}

- (void) addRehearsalMark: (NSString*) rehearsalMark {
	[super addRehearsalMark: rehearsalMark];
	
	if ([rehearsalMark isEqualToString: BAR_LINE_REHEARSAL_MARK_DA_CAPO])
		[self removeRehearsalMark: BAR_LINE_REHEARSAL_MARK_DAL_SEGNO];
	
	if ([rehearsalMark isEqualToString: BAR_LINE_REHEARSAL_MARK_DAL_SEGNO])
		[self removeRehearsalMark: BAR_LINE_REHEARSAL_MARK_DA_CAPO];
	
}

// serialization

- (void) encodeWithCoder: (NSCoder*) coder {
	[super encodeWithCoder: coder];
	[coder encodeInt: self.wrapsAfterBar forKey: @"wrapsAfterBar"];
	
}
- (NSString*) innerXMLString {
	NSMutableString* buffer = [NSMutableString string];
	
	if (repeatCount || (type && ![type isEqualToString: BAR_LINE_TYPE_SINGLE])) {
		[buffer appendString: @"<barline"];
		if (!(type == nil || [type isEqualToString: BAR_LINE_TYPE_SINGLE]))
			[buffer appendString: [NSString stringWithFormat: @" class=\"%@\"", type]];
		if (repeatCount)
			[buffer appendString: [NSString stringWithFormat: @" repeat=\"%i\"", repeatCount]];
		
		[buffer appendString: @"/>"];
		
	}
	[buffer appendString: [super innerXMLString]];
	
	return buffer;
	
}

- (NSString*) toXMLString {
	NSMutableString* buffer = [NSMutableString string];
	
	[buffer appendString: @"<closing>"];
	[buffer appendString: [self innerXMLString]];
	[buffer appendString: @"</closing>"];
	
	return buffer;
	
}

@end

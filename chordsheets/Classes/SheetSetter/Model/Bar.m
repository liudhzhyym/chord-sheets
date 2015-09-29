//
//  Bar.m
//  ChordPlayer
//
//  Created by Pattrick Kreutzer on 26.11.10.
//  Copyright 2010 wysiwyg* software design gmbh.
//

#import "Bar.h"

#import "AttributedChord.h"
#import "TimeSignature.h"

#import "NSString_XMLEscaping.h"
#import "NSMutableString_XMLComposing.h"


@interface Bar (Private)

- (void) registerBarLineElements: (ParserContext*) parserContext;
- (void) processBarChords: (ParserContext*) parserContext;

@end


@implementation Bar

// construction

- (id) init {
	if ((self = [super init])) {
		chords = [[NSMutableArray alloc] init];
		closingBarLine = [[ClosingBarLine alloc] init];
		
	}
	return self;
	
}

- (id) initWithCoder: (NSCoder*) coder {
	if ((self = [super init])) {
		openingBarLine = [[coder decodeObjectForKey: @"openingBarLine"] retain];
		if (chords)
			[chords release];
		chords = [[coder decodeObjectForKey: @"notes"] retain];
		if (closingBarLine)
			[closingBarLine release];
		closingBarLine = [[coder decodeObjectForKey: @"closingBarLine"] retain];
		
	}
	return self;
	
}

- (id) copyWithZone: (NSZone*) zone {
	Bar* instance = [[[self class] allocWithZone: zone] init];
	
	instance -> openingBarLine = [self.openingBarLine copyWithZone: zone];
	//instance -> chords = [self.chords copyWithZone: zone]; // needs deep copy
	if (instance -> chords)
		[instance -> chords release];
    instance -> chords = [[NSMutableArray alloc] initWithArray:[self chords] copyItems:YES];
	
	if (instance -> closingBarLine)
		[instance -> closingBarLine release];
	instance -> closingBarLine = [self.closingBarLine copyWithZone: zone];
	
	return instance;
	
}

// xml parsing

- (void) registerWithParserContext: (ParserContext*) parserContext {
	deferredSyncopation = NO;
	
	[parserContext registerElement: @"opening"
		withTarget: self selector: @selector (processOpening:)];
	[parserContext registerElement: @"closing"
		withTarget: self selector: @selector (processClosing:)];
	
	[parserContext registerElement: @"__TEXT__"
		withTarget: self selector: @selector (processBarChords:)];
	[parserContext registerElement: @"//syncopation"
		withTarget: self selector: @selector (processSyncopation:)];
	[parserContext registerElement: @"annotation"
		withTarget: self selector: @selector (processAnnotation:)];
	
	[parserContext registerElement: @"__FINISH__"
		withTarget: self selector: @selector (finishParsing:)];
	
}

- (void) processOpening: (ParserContext*) parserContext {
	// NSLog (@"opening");
	
	self.openingBarLine = [[[OpeningBarLine alloc] init] autorelease];
	currentParsingBarLine = openingBarLine;
	
	[parserContext registerElement: @"/keysignature"
		withTarget: self selector: @selector (processKeySignature:)];
	[parserContext registerElement: @"/timesignature"
		withTarget: self selector: @selector (processTimeSignature:)];
	
	[self registerBarLineElements: parserContext];
	
	[parserContext registerElement: @"ending"
		withTarget: self selector: @selector (processEnding:)];
	[parserContext registerElement: @"annotation"
		withTarget: self selector: @selector (processAnnotation:)];
	
	[parserContext registerElement: @"pause"
		withTarget: self selector: @selector (processPause:)];
	
}

- (void) processClosing: (ParserContext*) parserContext {
	// NSLog (@"closing");
	self.closingBarLine = [[[ClosingBarLine alloc] init] autorelease];
	currentParsingBarLine = closingBarLine;
	
	[self registerBarLineElements: parserContext];
	
}

- (void) registerBarLineElements: (ParserContext*) parserContext {
	[parserContext registerElement: @"barline"
		withTarget: self selector: @selector (processBarLine:)];
	[parserContext registerElement: @"rehearsalmark"
		withTarget: self selector: @selector (processRehearsalMark:)];
	
	[parserContext registerElement: @"simile"
		withTarget: self selector: @selector (processSimile:)];
	
}

- (void) processBarLine: (ParserContext*) parserContext {
	
	NSDictionary* attributes = [parserContext currentElementAttributes];	
	NSString* repeatAttribute = [attributes objectForKey: @"repeat"];
	uint repeatCount = repeatAttribute ? [repeatAttribute intValue] : 0;
	
	NSString* className = [attributes objectForKey: @"class"];
	
	[currentParsingBarLine setType: className];
	[currentParsingBarLine setRepeatCount: repeatCount];
	
}

- (void) processKeySignature: (ParserContext*) parserContext {
	// NSLog (@"key signature %@", parserContext.currentText);
	
	KeySignature* keySignature = [[KeySignature alloc] init];
	[keySignature setStringValue: parserContext.currentText];
	[parserContext flushCurrentText];
	
	openingBarLine.keySignature = [keySignature autorelease];
	
}

- (void) processTimeSignature: (ParserContext*) parserContext {
	// NSLog (@"time signature %@", parserContext.currentText);
	
	TimeSignature* timeSignature = [[TimeSignature alloc] init];
	[timeSignature setStringValue: parserContext.currentText];
	[parserContext flushCurrentText];
	
	openingBarLine.timeSignature = [timeSignature autorelease];
	
}

- (void) processRehearsalMark: (ParserContext*) parserContext {
	// NSLog (@"rehearsal mark");
	
	NSString* rehearsalMarkName =
		[parserContext.currentElementAttributes objectForKey: @"class"];
		
	if ([rehearsalMarkName isEqualToString: @"coda_dsal"]) {
		[currentParsingBarLine addRehearsalMark: BAR_LINE_REHEARSAL_MARK_CODA];
		[currentParsingBarLine addRehearsalMark: BAR_LINE_REHEARSAL_MARK_DAL_SEGNO];
		
	} else
		[currentParsingBarLine addRehearsalMark: rehearsalMarkName];
	
}

- (void) processEnding: (ParserContext*) parserContext {
	
	NSString* endingMarkName =
		[parserContext.currentElementAttributes objectForKey: @"count"];
	if (![endingMarkName length])
		endingMarkName = [[[parserContext.currentElementAttributes objectForKey: @"class"]componentsSeparatedByString: @"ending_"] objectAtIndex: 1];
	
	// NSLog (@"ending %@", endingMarkName);
	int voltaCount = MIN (3, [endingMarkName intValue]); // [[[endingMarkName componentsSeparatedByString: @"ending_"]
		// objectAtIndex: 1] intValue];
	
	[openingBarLine setVoltaCount: voltaCount];
	
}

- (void) processPause: (ParserContext*) parserContext {
	// NSLog (@"pause");
	
	if (!openingBarLine)
		openingBarLine = [OpeningBarLine new];
	
	[openingBarLine setBarMark: BAR_LINE_BAR_MARK_WHOLE_REST];
	
}

- (void) processSimile: (ParserContext*) parserContext {
	// NSLog (@"simile");
	
	NSString* simileClass =
		[parserContext.currentElementAttributes objectForKey: @"class"];
	
	if (!openingBarLine)
		openingBarLine = [OpeningBarLine new];
	
	if ([simileClass isEqualToString: @"double"])
		[openingBarLine setBarMark: BAR_LINE_BAR_MARK_TWO_BAR_SIMILE];
	else
		[openingBarLine setBarMark: BAR_LINE_BAR_MARK_SIMILE];
	
}

- (void) processSyncopation: (ParserContext*) parserContext {
	// NSLog (@"process syncopation");
	
	deferredSyncopation = YES;
	[parserContext flushCurrentText];
	
}

- (void) processAnnotation: (ParserContext*) parserContext {
	// NSLog (@"processAnnotation -- current text %@", parserContext.currentText);
	
	if ([parserContext.currentText length]) {
		[self processBarChords: parserContext];
		[parserContext flushCurrentText];
		
	}
	
	[parserContext registerElement: @"__TEXT__"
		withTarget: self selector: @selector (processAnnotationText:)];
	
}

- (void) processAnnotationText: (ParserContext*) parserContext {
	// NSLog (@"processAnnotation text -- current text %@", parserContext.currentText);
	
	if (currentProcessingChord)
		currentProcessingChord.annotation = [parserContext currentText];
	else {
		if (!openingBarLine)
			openingBarLine = [[OpeningBarLine alloc] init]; // compat
		
		openingBarLine.annotation = [parserContext currentText];
		
	}
	
}

- (void) processBarChords: (ParserContext*) parserContext {
	
	if (openingBarLine.clearsBar)
		return;
	
	NSString* text = [parserContext currentText];
    //NSLog(@"processBarChords on %@", text);
	NSArray* components = [text componentsSeparatedByString: @"\n"];
	
	for (int i = 0; i < [components count]; i++) {
		AttributedChord* chord = [[AttributedChord alloc] init];
		
		NSString* serial = [[components objectAtIndex: i] stringByTrimmingCharactersInSet:
			[NSCharacterSet whitespaceAndNewlineCharacterSet]
			
		];
		
		if ([serial isEqualToString: @"/"])
			parserContext -> parsingModeOld = YES;
		else if (parserContext -> parsingModeOld && ![serial length]) {
            [chord release];
			continue;
        }
		
		[chord parseStringValue: serial];
		if (deferredSyncopation) {
			deferredSyncopation = NO;
			chord.isSyncopic = YES;
			
		}
		[chords addObject: chord];
		currentProcessingChord = chord;
		
		[chord release];
		
	}
	
	// NSLog (@"chord serial: %@", serial);
	 //NSLog (@" gen chords %@", chords);
	
}

- (void) finishParsing: (ParserContext*) parserContext {
/*
	[openingBarLine updateLayout];
	[closingBarLine updateLayout];
*/
}

// properties

- (OpeningBarLine*) openingBarLine {
	return openingBarLine;
	
}

- (void) setOpeningBarLine: (OpeningBarLine*) _openingBarLine {
	if (openingBarLine == _openingBarLine)
		return;
	
	[openingBarLine release];
	openingBarLine = [_openingBarLine retain];
	
}

- (NSMutableArray*) chords {
	return chords;
	
}

- (ClosingBarLine*) closingBarLine {
	return closingBarLine;
	
}

- (void) setClosingBarLine: (ClosingBarLine*) _closingBarLine {
	if (closingBarLine == _closingBarLine)
		return;
	
	[closingBarLine release];
	closingBarLine = [_closingBarLine retain];
	
}

// modification

- (void) clear {
	for (int i = (int) [chords count]; i--;) {
		AttributedChord* chord = [[AttributedChord alloc] init];
		[chords replaceObjectAtIndex: i withObject: chord];
		[chord release];
		
	}
	
}

- (void) adaptForTimeSignature: (TimeSignature*) timeSignature {
	// return;
	
	int chordCount = (int) [chords count];
	int timeSignatureCount = [timeSignature chordCountForBar];
	
	
	if (chordCount > timeSignatureCount) {
		// NSLog(@"adjusting chords %@ to count %i", chords, timeSignatureCount);
		
		if (timeSignatureCount < 4) {
			for (int i = (int) [chords count]; i--;) {
				Chord* chord = [chords objectAtIndex: i];
				if (!chord.key)
					[chords removeObjectAtIndex: i];
				
			}
			chordCount = (int) [chords count];
			
		}
		// NSLog(@"adjusted chords %@ to count %i", chords, timeSignatureCount);
		
		if (chordCount > timeSignatureCount) {
			int numChordsToRemove = chordCount - timeSignatureCount;
			for (int i = numChordsToRemove; i--;)
				[chords removeLastObject];
			
		}
		
	}
	
	if (chordCount < timeSignatureCount) {
		int numChordsToAppend = timeSignatureCount - chordCount;
		// NSLog (@"appending %i chords", numChordsToAppend);
		
		for (int i = numChordsToAppend; i--;) {
			AttributedChord* chord = [[AttributedChord alloc] init];
			[chords addObject: chord];
			[chord release];
			
		}
		
	}
	
}

// serialization

- (NSString*) toXMLString {
	NSMutableString* buffer = [NSMutableString string];
	
	if (openingBarLine && !openingBarLine.isDefault)
		[buffer appendString: [openingBarLine toXMLString]];
	
	int usedChordCount = (int) [chords count];
	for (int i = usedChordCount; i--;) {
		AttributedChord* chord = [chords objectAtIndex: i];
		if ([chord isEmpty])
			usedChordCount--;
		else
			break;
		
	}
	
	for (int i = 0; i < usedChordCount; i++) {
		AttributedChord* chord = [chords objectAtIndex: i];
		if (i)
			[buffer appendString: @"/\n"];
		
		[buffer appendString: [chord toXMLString]];
		
	}
	
	if (closingBarLine && !closingBarLine.isDefault)
		[buffer appendString: [closingBarLine toXMLString]];
	
	if ([buffer length])
		[buffer setString: [NSString stringWithFormat: @"<bar>%@</bar>", buffer]];
	else
		[buffer setString: @"<bar/>"];
	
	if (closingBarLine.wrapsAfterBar)
		[buffer appendString: @"<break/>"];
	
	return buffer;
	
}

- (void) encodeWithCoder: (NSCoder*) coder {
	[coder encodeObject: openingBarLine forKey: @"openingBarLine"];
	[coder encodeObject: chords forKey: @"notes"];
	[coder encodeObject: closingBarLine forKey: @"closingBarLine"];
	
}

// deallocation

- (void) dealloc {
	
	if (openingBarLine)
		[openingBarLine release];
	if (chords)
		[chords release];
	if (closingBarLine)	
		[closingBarLine release];
	
	[super dealloc];
	
}

@end

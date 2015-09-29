//
//  Bar.h
//  ChordPlayer
//
//  Created by Pattrick Kreutzer on 26.11.10.
//  Copyright 2010 wysiwyg* software design gmbh.
//

#import <Foundation/Foundation.h>

#import "ParserContext.h"

#import "OpeningBarLine.h"
#import "ClosingBarLine.h"


@class AttributedChord;
@class TimeSignature;


@interface Bar : NSObject <NSCoding, NSCopying> {
	
	@protected
	
	OpeningBarLine* openingBarLine;
	NSMutableArray* chords;
	ClosingBarLine* closingBarLine;
	
	@private
	
	BarLine* currentParsingBarLine;
	AttributedChord* currentProcessingChord;
	
	BOOL deferredSyncopation;
	
}

@property (nonatomic, readwrite, retain) OpeningBarLine* openingBarLine;
- (NSMutableArray*) chords;
@property (nonatomic, readwrite, retain) ClosingBarLine* closingBarLine;

- (void) clear;
- (void) adaptForTimeSignature: (TimeSignature*) timeSignature;

- (NSString*) toXMLString;

- (void) registerWithParserContext: (ParserContext*) parserContext;

@end

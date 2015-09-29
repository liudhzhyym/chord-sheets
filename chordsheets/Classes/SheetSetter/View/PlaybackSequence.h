//
//  PlaybackSequence.h
//  Chord Sheets
//
//  Created by Pattrick Kreutzer on 01.02.12.
//  Copyright (c) 2012 wysiwyg* software design gmbh.
//	Released into the public domain in 2015. http://creativecommons.org/publicdomain/zero/1.0/
//

#import <Foundation/Foundation.h>

@class Sheet;
@class AttributedChord;
@class OpeningBarLine;

@class PlaybackSequenceStep;
@class TimeSignature;


@interface PlaybackSequence : NSObject {
	
	@public
	
	NSMutableArray* sequence;
	NSArray* sequenceCopy;
	
	@protected
	
	NSArray* bars;
	NSMutableArray* copiedBars;
	
	NSMutableArray* timeSignatures;
	
	@private
	
	BOOL didEncounterFine;
	
}

- (void) buildFromSheet: (Sheet*) sheet;
- (void) advanceToChord: (AttributedChord*) chord;

- (NSMutableArray*) builtStructureInRange: (NSRange) range voltaCount: (int) voltaCount;
- (NSMutableArray*) expandedStructureInRange: (NSRange) range voltaCount: (int) voltaCount;


- (BOOL) hasNextStep;
- (PlaybackSequenceStep*) nextStep;

@end


@interface PlaybackSequenceStep : NSObject {
	
	@public
	
	NSUInteger barIndex;
	int chordIndex;
	
	AttributedChord* originalChord;
	AttributedChord* chord;
	OpeningBarLine* openingBarLine;
	
	float duration;
	
	TimeSignature* timeSignature;
	
}


@end

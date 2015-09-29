//
//  PlaybackSequence.m
//  Chord Sheets
//
//  Created by Pattrick Kreutzer on 01.02.12.
//  Copyright (c) 2012 wysiwyg* software design gmbh.
//	Released into the public domain in 2015. http://creativecommons.org/publicdomain/zero/1.0/
//

#import "PlaybackSequence.h"

#import "Sheet.h"
#import "Bar.h"
#import "AttributedChord.h"


@interface PlaybackSequence (Private)

+ (NSRange) nextRangeInList: (NSMutableArray*) list;

- (int) indexOfCodaFromBarIndex: (int) barIndex;
- (int) indexOfFineFromBarIndex: (int) barIndex;

- (void) copyBar: (Bar*) bar toSequence: (NSMutableArray*) sequence
	originalBarIndex: (NSUInteger) originalBarIndex originalChordIndex: (int) originalChordIndex openingBarLine: (OpeningBarLine*) openingBarLine;

@end


@implementation PlaybackSequence

- (id) init {
	if (self = [super init]) {
		sequence = [NSMutableArray new];
		
	}
	return self;
	
}

// construction

- (void) buildFromSheet: (Sheet*) sheet {
	
	// build tables
	
	didEncounterFine = NO;
	
	bars = sheet -> bars;
	copiedBars = [NSMutableArray new];
	for (int i = (int) [bars count]; i--;)
		[copiedBars addObject: [NSNull null]];
	
	timeSignatures = [NSMutableArray new];
	
	TimeSignature* currentTimeSignature = nil;
	
	for (Bar* bar in bars) {
		if (bar.openingBarLine.timeSignature)
			currentTimeSignature = bar.openingBarLine.timeSignature;
		
		[timeSignatures addObject: currentTimeSignature];
		
	}
	
	[sequence release];
	
	sequence = [self builtStructureInRange: NSMakeRange (0, [bars count]) voltaCount: 0];
//	sequence = [self expandedStructureInRange: NSMakeRange (0, [bars count])];
	[sequence retain];
	
	[timeSignatures release];
	
	
	// set sequence timings
	
	PlaybackSequenceStep* lastStep = nil;
	float lastRatio = 0.f;
	
	for (PlaybackSequenceStep* step in sequence) {
		TimeSignature* timeSignature = step -> timeSignature;
		float ratio =
			timeSignature.numerator / [timeSignature chordCountForBar] *
			4.f / timeSignature.denominator;
		
		if ([step -> chord isSyncopic]) {
			if (lastStep != nil) {
				lastStep -> duration -= .5f * lastRatio;
				
			}
			step -> duration = step -> duration + .5f;
			
		}
		step -> duration = step -> duration * ratio;
		
		lastStep = step;
		lastRatio = ratio;
		
	}
	
	[copiedBars release];
	
	sequenceCopy = [sequence copy];
	
	// NSLog (@"did build sequence %@", sequence);
	// NSLog(@"sequence count %i", [sequence count]);
	
}

- (NSMutableArray*) builtStructureInRange: (NSRange) range voltaCount: (int) voltaCount {
	
	NSMutableArray* currentSequence = [NSMutableArray new];
	
	NSMutableArray* codaStack = [NSMutableArray new];
	NSMutableArray* segnoStack = [NSMutableArray new];
	
	NSMutableArray* innerRanges = [NSMutableArray new];
	
	int flushedIndex = 0;
	
	for (int i = 0; i < range.length; i++) {
		int cursor = i + (int) range.location;
		Bar* bar = [bars objectAtIndex: cursor];
		
		
		NSSet* openingRehearsalMarks = bar.openingBarLine.rehearsalMarks;
		if ([openingRehearsalMarks containsObject: BAR_LINE_REHEARSAL_MARK_CODA])
			[codaStack addObject: [NSNumber numberWithInt: cursor]];
		
		if ([openingRehearsalMarks containsObject: BAR_LINE_REHEARSAL_MARK_SEGNO])
			[segnoStack addObject: [NSNumber numberWithInt: cursor]];
		
		// http://piano.about.com/od/musicaltermssymbols/ss/2Int_SheetMusic_6.htm
		
		NSSet* closingRehearsalMarks = bar.closingBarLine.rehearsalMarks;
		
		BOOL hasDelSegno = [closingRehearsalMarks containsObject: BAR_LINE_REHEARSAL_MARK_DAL_SEGNO];
		BOOL hasDaCapo = [closingRehearsalMarks containsObject: BAR_LINE_REHEARSAL_MARK_DA_CAPO];
		BOOL hasCoda = [closingRehearsalMarks containsObject: BAR_LINE_REHEARSAL_MARK_CODA];
		BOOL hasFine = [closingRehearsalMarks containsObject: BAR_LINE_REHEARSAL_MARK_FINE];
		
		if (hasDelSegno) {
			if (hasCoda) {
				int lastSegnoLocation = [[segnoStack lastObject] intValue];
				
				[currentSequence addObjectsFromArray:
					[self expandedStructureInRange: NSMakeRange (flushedIndex, cursor - flushedIndex + 1)
						voltaCount: voltaCount]
					
				];
				
				int nextCodaIndex = [self indexOfCodaFromBarIndex: lastSegnoLocation];
				[currentSequence addObjectsFromArray:
					[self expandedStructureInRange: NSMakeRange (lastSegnoLocation, nextCodaIndex - lastSegnoLocation + 0) voltaCount: voltaCount + 1]
					
				]; // Repeat from the last segno; play until you reach the first coda
				
				 flushedIndex = cursor + 1; // nextCodaIndex + 0;
				
				// then skip to the next coda sign
				
			} else { // al fine
				
				[currentSequence addObjectsFromArray:
					[self expandedStructureInRange: NSMakeRange (flushedIndex, cursor - flushedIndex + 1)
						voltaCount: voltaCount]
					
				];
				
				int lastSegnoLocation = [[segnoStack lastObject] intValue];
				
				if (hasFine) {
					int fineIndex = [self indexOfFineFromBarIndex: lastSegnoLocation];
					[currentSequence addObjectsFromArray:
						[self expandedStructureInRange: NSMakeRange (lastSegnoLocation, fineIndex - lastSegnoLocation + 1)
							voltaCount: voltaCount + 1]
						
					]; // Repeat from the last segno, and end the song at the word fine.
					
					flushedIndex = (int) range.location + (int) range.length;
					i = (int) range.length; // enough expansion, boil out
					
				} else {
					[currentSequence addObjectsFromArray:
						[self expandedStructureInRange: NSMakeRange (lastSegnoLocation, cursor - lastSegnoLocation + 1)
							voltaCount: voltaCount + 1]
						
					];
					flushedIndex = cursor + 1;
					
				}
				
			}
			
		}
		
		if (hasDaCapo) {
			if (hasCoda) {
				[currentSequence addObjectsFromArray:
					[self expandedStructureInRange: NSMakeRange (flushedIndex, cursor - flushedIndex + 1)
						voltaCount: voltaCount]
					
				]; // play from the beginnging
				
				int firstCodaIndex = [self indexOfCodaFromBarIndex: 0] - 1;
				[currentSequence addObjectsFromArray:
					[self expandedStructureInRange: NSMakeRange (flushedIndex * 0, firstCodaIndex + 1)
						voltaCount: voltaCount + 1]
					
				]; // repeat from the beginning; play until you reach a coda (or the phrase al coda)
				
				flushedIndex = cursor + 1;
				
				// then jump forward to the next coda sign to continue playing
				
			} else { // al fine
				[currentSequence addObjectsFromArray:
					[self expandedStructureInRange: NSMakeRange (flushedIndex, cursor - flushedIndex + 1)
						voltaCount: voltaCount]
					
				];
				
				[bar.closingBarLine -> rehearsalMarks removeObject: BAR_LINE_REHEARSAL_MARK_DA_CAPO];
				
				int fineIndex = [self indexOfFineFromBarIndex: (int) range.location];
				[currentSequence addObjectsFromArray:
					[self builtStructureInRange: NSMakeRange (range.location, fineIndex + 1 - range.location) voltaCount: voltaCount + 1]
					
				];
				
				[bar.closingBarLine -> rehearsalMarks addObject: BAR_LINE_REHEARSAL_MARK_DA_CAPO];
				
				flushedIndex = (int) range.location + (int) range.length;
				i = (int) range.length;
				
			}
			
		}
		
	}
	[currentSequence addObjectsFromArray:
		[self expandedStructureInRange: NSMakeRange (flushedIndex, range.location + range.length - flushedIndex)
			voltaCount: voltaCount]
		
	];
	
	// NSLog (@"coda stack %@", codaStack);
	// NSLog (@"segno stack %@", segnoStack);
	
	[innerRanges release];
	
	[codaStack release];
	[segnoStack release];
	
	return [currentSequence autorelease];
	
//	return [self expandedStructureInRange: range];
	
}

- (int) indexOfCodaFromBarIndex: (int) barIndex {
	for (int i = barIndex; i < [bars count]; i++) {
		Bar* bar = [bars objectAtIndex: i];
		if ([bar.openingBarLine.rehearsalMarks containsObject: BAR_LINE_REHEARSAL_MARK_CODA])
			return i;
		
		if ([bar.closingBarLine.rehearsalMarks containsObject: BAR_LINE_REHEARSAL_MARK_CODA])
			return MIN (i + 1, (int) [bars count] - 1);
		
	}
	return (int) [bars count] - 1;
	
}

- (int) indexOfFineFromBarIndex: (int) barIndex {
	for (int i = barIndex; i < [bars count]; i++) {
		Bar* bar = [bars objectAtIndex: i];
		if ([bar.closingBarLine.rehearsalMarks
			containsObject: BAR_LINE_REHEARSAL_MARK_FINE])
			return i;
		
	}
	return (int) [bars count] - 1;
	
}

+ (BOOL) openingBarLineResetsRange: (OpeningBarLine*) openingBarLine {
	return openingBarLine.repeatCount != 0;
	
}

- (NSArray*) expandedStructureInRange: (NSRange) range voltaCount: (int) voltaCount{
	
	// NSLog (@"expanding range %i -- %i", range.location, range.length);
	
	if (didEncounterFine || !range.length)
		return [NSArray array];
	
	NSMutableArray* innerRanges = [NSMutableArray new];
	
	long openingBarCursor = range.location;
	int openingBarBalance = 0;
	
	//BOOL willCloseRepeat = NO;
	
	int repeatCount; // = ((Bar*) [bars objectAtIndex: range.location + range.length - 1]).
		// closingBarLine.repeatCount + 1;
	
	for (int i = 0; i < range.length - 0; i++) {
		repeatCount = 1;
		long cursor = i + range.location;
		
		Bar* bar = [bars objectAtIndex: cursor];
		OpeningBarLine* openingBarLine = bar.openingBarLine;
		ClosingBarLine* closingBarLine = bar.closingBarLine;
		
		// NSLog (@"[%li] op type %@", cursor, openingBarLine.type);
		
		if ([PlaybackSequence openingBarLineResetsRange: openingBarLine]) {
			openingBarBalance++;
			openingBarCursor = cursor;
			
		}
		
		BOOL didCloseRepeat = NO;
		
		if (closingBarLine.repeatCount) {
			//willCloseRepeat = YES;
			repeatCount = closingBarLine.repeatCount + 1;
			
			int currentVolta = 0;
			while (cursor + 1 < [bars count]) {
				Bar* nextBar = [bars objectAtIndex: cursor + 1];
				
				if (nextBar.openingBarLine.voltaCount)
					currentVolta = nextBar.openingBarLine.voltaCount;
				
				if (!currentVolta)
					break;
				
				if ([PlaybackSequence openingBarLineResetsRange: nextBar.openingBarLine])
					break;
				
				i++;
				cursor++;
				
				if ([nextBar.closingBarLine.type isEqualToString: BAR_LINE_TYPE_DOUBLE])
					break;
				
				
			}
			didCloseRepeat = YES;
			
		}
		
		if (didCloseRepeat) {
			openingBarBalance--;
			
			if (openingBarBalance <= 0) {
				[innerRanges addObject: 
					[NSArray arrayWithObjects:
						[NSNumber numberWithLong: openingBarCursor],
						[NSNumber numberWithLong: cursor - openingBarCursor + 1],
						nil
						
					]
					
				];
				
			}
			openingBarCursor = cursor + 1;
			//willCloseRepeat = NO;
			
		}
		
	}
	// NSLog (@"inner ranges %@.", innerRanges);
	
	NSMutableArray* currentSequence = [NSMutableArray new];
	
	BOOL hasRepeatCount = repeatCount > 1;
	
	NSRange currentInnerRange = [PlaybackSequence nextRangeInList: innerRanges];
	NSRange lastInnerRange = currentInnerRange;
	
	if (currentInnerRange.location == range.location &&
		currentInnerRange.length == range.length) {
		currentInnerRange = [PlaybackSequence nextRangeInList: innerRanges]; // no need to enter recursion
		lastInnerRange = range;
		
	}
	
	for (int j = 0; j < repeatCount; j++) {
		int currentVoltaCount = 0;
		int voltaPass = j + 1;
		int simileCount = 0, simileOffset = 0;
		
		for (long i = 0; i < range.length; i++) {
			long cursor = i + range.location;
			
			if (cursor < currentInnerRange.location) {
				Bar* bar = [bars objectAtIndex: cursor];
				
				OpeningBarLine* openingBarLine = bar.openingBarLine;
				
				if ([openingBarLine.barMark isEqualToString: BAR_LINE_BAR_MARK_WHOLE_REST])
					simileCount = 1, simileOffset = 0;
				else if ([openingBarLine.barMark isEqualToString: BAR_LINE_BAR_MARK_SIMILE])
					simileCount = simileOffset = 1;
				else if ([openingBarLine.barMark isEqualToString: BAR_LINE_BAR_MARK_TWO_BAR_SIMILE])
					simileCount = simileOffset = 2;
				
				if (openingBarLine.voltaCount)
					currentVoltaCount = openingBarLine.voltaCount;
				
				BOOL isInInnerRange =
					lastInnerRange.location <= cursor &&
					lastInnerRange.location + lastInnerRange.length > cursor;
				
				int voltaToUse = isInInnerRange || hasRepeatCount ?
					voltaPass : voltaCount + 1;
				if (!currentVoltaCount || currentVoltaCount == voltaToUse) {
					if (simileCount) {
						simileCount--;
						
						long simileIndex = cursor - simileOffset;
						if (simileIndex >= 0) {
							if (simileOffset > 0) {
								Bar* barToCopy = [copiedBars objectAtIndex: simileIndex];
								[self copyBar: barToCopy toSequence: currentSequence
									originalBarIndex: simileOffset == 2 ? simileCount ? cursor : cursor - 1 : cursor
									originalChordIndex: -1 openingBarLine: openingBarLine];
								[copiedBars replaceObjectAtIndex: cursor withObject: barToCopy];
								
							} else {
								Bar* barCopy = [bar copy];
								[barCopy adaptForTimeSignature: [timeSignatures objectAtIndex: cursor]];
								[self copyBar: barCopy toSequence: currentSequence originalBarIndex: cursor originalChordIndex: -1 openingBarLine: openingBarLine];
								[copiedBars replaceObjectAtIndex: cursor withObject: bar];
								[barCopy release];
								
							}
							
						}
						
					} else {
						[self copyBar: bar toSequence: currentSequence originalBarIndex: cursor originalChordIndex: 0 openingBarLine: openingBarLine];
						[copiedBars replaceObjectAtIndex: cursor withObject: bar];
						
					}
					
				}
				
			} else if (cursor == currentInnerRange.location) {
				do {
					// NSLog(@"should expand range %i -- %i", currentInnerRange.location, currentInnerRange.length);
					
					lastInnerRange = currentInnerRange;
					currentInnerRange = [PlaybackSequence nextRangeInList: innerRanges];
					
				} while (cursor == currentInnerRange.location);
				
				[currentSequence addObjectsFromArray:
					[self expandedStructureInRange: lastInnerRange voltaCount: voltaCount]
					
				];
				if (lastInnerRange.length) {
					i = lastInnerRange.location + lastInnerRange.length - 1 - range.location;
					if (lastInnerRange.location + lastInnerRange.length ==
						range.location + range.length)
						repeatCount = 0;
					
				}
				
			}
			
		}
		
	}
	
	[innerRanges release];
	
	// NSLog (@"current sequence %@.", currentSequence);
	
	return [currentSequence autorelease];
	
}

+ (NSRange) nextRangeInList: (NSMutableArray*) list {
	
	if ([list count]) {
		NSArray* entry = [list objectAtIndex: 0];
		[list removeObjectAtIndex: 0];
		return NSMakeRange (
			[[entry objectAtIndex: 0] intValue],
			[[entry objectAtIndex: 1] intValue]
			
		);
		
	} else {
		return NSMakeRange (INT32_MAX, 0);
		
	}
	
}

- (void) copyBar: (Bar*) bar toSequence: (NSMutableArray*) currentSequence
	originalBarIndex: (NSUInteger) originalBarIndex originalChordIndex: (int) originalChordIndex openingBarLine: (OpeningBarLine*) openingBarLine {
	
	if (didEncounterFine)
		return;
	
	// NSLog(@"adding bar %i", originalBarIndex);
	
	NSArray* chords = bar.chords;
	
	for (long i = 0; i < [chords count]; i++) {
		
		PlaybackSequenceStep* step = [PlaybackSequenceStep new];
		AttributedChord* chord = [chords objectAtIndex: i];
		
		step -> barIndex = originalBarIndex;
		step -> chordIndex = (int) (
			originalChordIndex < 0 ?
				originalChordIndex : i);
		
		step -> originalChord = chord;
		step -> chord = chord.key ? chord : nil;
		step -> openingBarLine = openingBarLine;
		
		step -> duration = 1.f;
		
		step -> timeSignature = [timeSignatures objectAtIndex: originalBarIndex];
		
		[currentSequence addObject: step];
		// NSLog(@"added step %@ at index %i", step, [sequence count] - 1);
		
		[step release];
		
	}
	
	NSSet* closingRehearsalMarks = bar.closingBarLine.rehearsalMarks;
	
	BOOL hasDelSegno = [closingRehearsalMarks containsObject: BAR_LINE_REHEARSAL_MARK_DAL_SEGNO];
	BOOL hasDaCapo = [closingRehearsalMarks containsObject: BAR_LINE_REHEARSAL_MARK_DA_CAPO];
	// BOOL hasCoda = [closingRehearsalMarks containsObject: BAR_LINE_REHEARSAL_MARK_CODA];
	BOOL hasFine = [closingRehearsalMarks containsObject: BAR_LINE_REHEARSAL_MARK_FINE];

		
	if (hasFine && !(hasDaCapo || hasDelSegno)) {
		// didEncounterFine = YES; // disabled stopping on fine
		
	}
	
	
}

// playback

- (BOOL) hasNextStep {
	return [sequence count] > 0;
	
}

- (PlaybackSequenceStep*) nextStep {
	PlaybackSequenceStep* step = [[sequence objectAtIndex: 0] retain];
	[sequence removeObjectAtIndex: 0];
	return [step autorelease];
	
}

- (void) advanceToChord: (id) object {
	if ([sequenceCopy count] == 0)
		return;
	
	[sequence release];
	sequence = [sequenceCopy mutableCopy];
	
	
	if ([object isKindOfClass: [AttributedChord class]]) {
		AttributedChord* chord = object;
		// NSLog (@"should advance to chord %@", chord);
		
		while ([sequence count]) {
			PlaybackSequenceStep* currentStep = [sequence objectAtIndex: 0];
			
			if (currentStep -> originalChord == chord) {
				// NSLog (@"found %@", currentStep);
				break;
				
			}
			[sequence removeObjectAtIndex: 0];
			
		}
		
	} else if ([object isKindOfClass: [OpeningBarLine class]]) {
		OpeningBarLine* openingBarLine = object;
		// NSLog (@"should advance to opening bar line %@", openingBarLine);
		
		while ([sequence count]) {
			PlaybackSequenceStep* currentStep = [sequence objectAtIndex: 0];
			
			if (currentStep -> openingBarLine == openingBarLine) {
				// NSLog (@"found %@", currentStep);
				break;
				
			}
			[sequence removeObjectAtIndex: 0];
			
		}
		
	}
	
}

// finalizer

- (void) dealloc {
	[sequence release];
	[sequenceCopy release];
	
	[super dealloc];
	
}


@end


@implementation PlaybackSequenceStep

- (NSString*) description {
	
	return [NSString stringWithFormat: @"[PlaybackSequenceStep barIndex: %lu chordIndex: %i chord: %@ time signature: %@ duration: %f]", (unsigned long)barIndex, chordIndex, chord, timeSignature.stringValue, duration];
	
}

@end

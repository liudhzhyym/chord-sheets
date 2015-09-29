//
//  BarLayer.m
//  SheetSetter
//
//  Created by Pattrick Kreutzer on 08.06.10.
//  Copyright 2010 wysiwyg* software design gmbh.
//

#import "Bar.h"
#import "AttributedChord.h"

#import "BarLayer.h"

#import "ChordLayer.h"
#import "AnnotationLayer.h"


@interface BarLayer (Private)

- (float) leftInset;
- (float) closingRehearsalMarksSpacing;

@end

@implementation BarLayer

- (id) init {
	if ((self = [super init])) {
		self.bounds = CGRectMake (0, 0, 1, 1);
		self.anchorPoint = CGPointMake (0, 0);
		
		chords = [[NSMutableArray alloc] init];
		
		openingBarLine = [[OpeningBarLineLayer layer] retain];
		[self addSublayer: openingBarLine];
		
		closingBarLine = [[ClosingBarLineLayer layer] retain];
		[self addSublayer: closingBarLine];
		
//		self.shouldRasterize = YES;
		
	}
	return self;
	
}

- (void) setScale: (float) _scale {
	 self.shouldRasterize = _scale < 2;
	[super setScale: _scale];
	
}


@synthesize keySignatureLayer;
@synthesize timeSignatureLayer;

@synthesize annotation;

@synthesize openingBarLine;
@synthesize closingBarLine;

@synthesize chords;

//

- (void) updateFromModelObject {
	Bar* bar = modelObject;
	
	if (isLocked) {
		if ([bar.chords count] > 0)
			[bar.chords removeAllObjects];
		
	}
	
	openingBarLine.modelObject = bar.openingBarLine ?
		bar.openingBarLine : (bar.openingBarLine = [[[OpeningBarLine alloc] init] autorelease]);
	closingBarLine.modelObject = bar.closingBarLine;
	
	if (DISPLAYS_KEY_SIGNATURES) {
		if (!keySignatureLayer) {
			keySignatureLayer = [KeySignatureLayer layer];
			[self addSublayer: keySignatureLayer];
			
		}
		KeySignature* keySignature = bar.openingBarLine.keySignature;
		keySignatureLayer.modelObject = keySignature;
		
	} else {
		if (keySignatureLayer) {
			[keySignatureLayer removeFromSuperlayer];
			[scalableSublayers removeObject: keySignatureLayer];
			keySignatureLayer = nil;
			
		}
		
	}
	
	TimeSignature* timeSignature = bar.openingBarLine.timeSignature;
	if (timeSignature) {
		if (!timeSignatureLayer) {
			timeSignatureLayer = [TimeSignatureLayer layer];
			[self addSublayer: timeSignatureLayer];
			
		}
		timeSignatureLayer.modelObject = timeSignature;
		
	} else {
		if (timeSignatureLayer) {
			[timeSignatureLayer removeFromSuperlayer];
			[scalableSublayers removeObject: timeSignatureLayer];
			timeSignatureLayer = nil;
			
		}
		
	}
	
	int numBarChords = (int) [bar.chords count];
	for (int i = 0; i < numBarChords; i++) {
		
		AttributedChord* chord = [bar.chords objectAtIndex: i];
		ChordLayer* chordLayer = nil;
		
		if (i < [chords count]) {
			chordLayer = [chords objectAtIndex: i];
			
		} else {
			chordLayer = [ChordLayer layer];
			[chords addObject: chordLayer];
			
		}
		chordLayer.modelObject = chord;
		
		chordLayer -> shadowLayer.hidden = i == numBarChords - 1;
		
		[self addSublayer: chordLayer];
		
	}
	
	const int numChords = (int) [chords count];
	for (int i = (int) [bar.chords count]; i < numChords; i++) {
		ChordLayer* chordLayer = [chords lastObject];
		[chordLayer removeFromSuperlayer];
		[scalableSublayers removeObject: chordLayer];
		[chords removeLastObject];
		
	}
	
	NSString* annotationText = bar.openingBarLine.annotation;
	if (annotationText) {
		if (!annotation) {
			annotation = [AnnotationLayer layer];
			annotation.drawsBorder = YES;
			
		}
		annotation.scaledPosition = CGPointMake (0, -6 - 1);
		annotation.text = annotationText;
		[self presentSublayer: annotation visible: YES];
		
	} else {
		if (annotation) {
			[annotation removeFromSuperlayer];
			[scalableSublayers removeObject: annotation];
			annotation = nil;
			
		}
		
	}
	
	[self setNeedsUpdateLayout];
	
}

// layout

#define CHORD_SPACING 3
#define BAR_SPACING 2 * CHORD_SPACING / 1
#define SIGNATURE_SPACING 1.5

#define CHORD_Y_OFFSET 12


- (float) signaturesWidth {
	[self updateLayout];
	return signaturesWidth;
	
}

- (void) setNeedsUpdateLayout {
	needsUpdateLayout = YES;
	
}

- (void) updateLayout {
	if (!needsUpdateLayout)
		return;
	needsUpdateLayout = NO;
	
	needsRecalculateInnerWidth = needsRecalculateInnerWidthIncludingAnnotation = YES;
	needsRecalculateWidth = needsRecalculateWidthIncludingAnnotation = YES;
	
	float cursor = 0;
	
	Bar* bar = modelObject;
	if (keySignatureLayer) {
		// KeySignature* keySignature = bar.openingBarLine.keySignature;
		keySignatureLayer.scaledPosition = CGPointMake (cursor, keySignatureLayer.scaledPosition.y);
		cursor += keySignatureLayer.width + SIGNATURE_SPACING;
		
	}
	TimeSignature* timeSignature = bar.openingBarLine.timeSignature;
	if (timeSignature) {
		timeSignatureLayer.scaledPosition = CGPointMake (cursor, timeSignatureLayer.scaledPosition.y);
		cursor += timeSignatureLayer.width + SIGNATURE_SPACING;
		
	}
	signaturesWidth = cursor;
	
	openingBarLine.scaledPosition = CGPointMake (cursor, openingBarLine.scaledPosition.y);
	
	if (cursor == 0.f)
		cursor = self.leftInset;
	
	if (annotation) {
		float annotationXOff = 1;
		if (openingBarLine.rehearsalMark && !openingBarLine.rehearsalMark.hidden) {
			annotationXOff += openingBarLine.rehearsalMark.scaledPosition.x +
				(!openingBarLine.voltaMark || openingBarLine.voltaMark.hidden ? openingBarLine.rehearsalMark.width : 6) + 2;
			
		} else if (openingBarLine.voltaMark && openingBarLine.voltaMark && !openingBarLine.voltaMark.hidden) {
			annotationXOff += [openingBarLine insetOfNarrowBar] + 15 + 10; // 15
			
		} else {
			annotationXOff += [openingBarLine insetOfNarrowBar] + 2;
			
		}
		annotation.scaledPosition = CGPointMake (cursor + annotationXOff, annotation.scaledPosition.y);
		
	}
	
	cursor += openingBarLine.width;
	leftBound = cursor;
	cursor += BAR_SPACING;
	
	chordsWidth = cursor;
	chordsDescendantsWidth = 0;
	for (ChordLayer* chordLayer in chords) {
		if (chordLayer.previousEditableElement &&
			[chordLayer.previousEditableElement isKindOfClass: [ChordLayer class]]) {
			ChordLayer* previousChordLayer = (ChordLayer*) chordLayer.previousEditableElement;
			if ([chordLayer.chordName.text length] &&
				[chordLayer.chordName.text characterAtIndex: 0] == 'A') {
				if ([previousChordLayer.chordQuality.text length])
					cursor -= 1.5;
				else if (previousChordLayer.chordName.accidental && !previousChordLayer.chordName.accidental.hidden)
					cursor -= 3;
				
			}
			if (chordLayer.slash && !chordLayer.slash.hidden) {
				chordsDescendantsWidth =
					cursor - (float) chordsWidth +
					(float) chordLayer.bassKey.scaledPosition.x +
					(float) chordLayer.bassKey.fullWidth - 1;
				
			}
			
			if (chordLayer.syncopation && !chordLayer.syncopation.hidden) {
				cursor += 11;
				
			}
			
		} else {
			if (chordLayer.syncopation && !chordLayer.syncopation.hidden) {
				cursor += 6;
				
			}
			
		}
		
		chordLayer -> barOffset = cursor;
		
		cursor += [chordLayer fullWidth];
		cursor += CHORD_SPACING;
		// NSLog (@"cursor %f", cursor);
		
	}
	chordsOffset = cursor;
	
	chordsWidth = cursor - chordsWidth;
	needsExpandChords = YES;
	
	cursor += BAR_SPACING;
	closingBarLine.scaledPosition = CGPointMake (
		[self signaturesWidth] + openingBarLine.width + BAR_SPACING + self.innerWidth + BAR_SPACING +
			closingBarLine.width + self.closingRehearsalMarksSpacing, closingBarLine.scaledPosition.y);

extern BOOL optimizeLayout;

if (!optimizeLayout)
	if (openingBarLine.barMark && !openingBarLine.barMark.hidden) {
		if ([((OpeningBarLine*)	openingBarLine.modelObject).barMark isEqualToString: BAR_LINE_BAR_MARK_TWO_BAR_SIMILE]) {
			openingBarLine.barMark.scaledPosition = CGPointMake (
				closingBarLine.scaledPosition.x - openingBarLine.barMark.width / 2 - 9 -
					openingBarLine.scaledPosition.x,
				openingBarLine.barMark.scaledPosition.y
				
			);
			
		} else {
			openingBarLine.barMark.scaledPosition = CGPointMake (
				(CGFloat) (leftBound + (self.innerWidth - openingBarLine.barMark.width + BAR_SPACING) / 2 + .4 -
					openingBarLine.scaledPosition.x),
				openingBarLine.barMark.scaledPosition.y
				
			);
			
		}
		
	}
	
	(void) cursor;
	
	localBounds = CGRectMake (
		0, 0,
		closingBarLine.scaledPosition.x + 4, self.height
		
	);
	
	// NSLog (@"closing %f", self.innerWidth);
	// NSLog (@"layout bar with scale %f", scale);
	
}

//

- (float) innerWidth {
	if (needsRecalculateInnerWidth) {
		needsRecalculateInnerWidth = NO;
		
		[self updateLayout];
		
		float maxBound =
			(float) -openingBarLine.width - (float) openingBarLine.scaledPosition.x - (float) closingBarLine.width + 4;
		
		calculatedInnerWidth = MAX (
			MAX (self.leftInset + chordsWidth, maxBound),
			16.f
			
		);
		
	}
	return calculatedInnerWidth;
	
}

- (float) innerWidthIncludingAnnotation {
	if (needsRecalculateInnerWidthIncludingAnnotation) {
		needsRecalculateInnerWidthIncludingAnnotation = NO;
		
		[self updateLayout];
		
		double maxBound = (annotation ? annotation.scaledPosition.x + annotation.width - 1 : 0) -
			(float) openingBarLine.width - (float) openingBarLine.scaledPosition.x - (float) closingBarLine.width + 4;
		
		calculatedInnerWidthIncludingAnnotation = MAX (
			MAX (self.leftInset + chordsWidth, (float) maxBound),
			16.f
			
		);
		
	}
	return calculatedInnerWidthIncludingAnnotation;
	
}

- (float) leftInset {
	float leftInset = 0;
	if ([chords count]) {
		ChordLayer* chordLayer = [chords objectAtIndex: 0];
		if (((AttributedChord*) chordLayer.modelObject).isSyncopic) {
			ClosingBarLineLayer* prevElement = (ClosingBarLineLayer*) openingBarLine.previousEditableElement;
			if (prevElement && [prevElement isKindOfClass: [ClosingBarLineLayer class]]) {
				if (!((BarLayer*) prevElement -> designatedSuperlayer) -> isLastInLine) {
					NSString* prevElementType = ((BarLine*) prevElement.modelObject).type;
					NSString* openingBarType = ((BarLine*) openingBarLine.modelObject).type;
					
					if ((!prevElementType || [prevElementType isEqualToString: BAR_LINE_TYPE_SINGLE]) &&
						(!openingBarType || [openingBarType isEqualToString: BAR_LINE_TYPE_SINGLE]))
						leftInset += 4.5;
					
					if (prevElement.repeatCountLabel && !prevElement.repeatCountLabel.hidden)
						leftInset += 9.5;
					else if ([prevElement rehearsalMarksCombinedWidth] != 0.f)
						leftInset += 5;
					
				}
				
			}
			
		}
		
	}
	return leftInset;
	
}

- (float) closingRehearsalMarksSpacing {
	float rehearsalMarksWidth = closingBarLine.rehearsalMarksCombinedWidth;
	
	if (rehearsalMarksWidth != 0) {
		float innerWidth = [self innerWidth] - chordsDescendantsWidth;
		return MAX (0, rehearsalMarksWidth - innerWidth + 6 + BAR_SPACING - closingBarLine.width);
		
	} else
		return 0;
	
}

- (float) width {
	
	if (needsRecalculateWidth) {
		[self updateLayout];
		needsRecalculateWidth = NO;
		
		calculatedWidth = [self signaturesWidth] + [openingBarLine width] +
			self.innerWidth + 2 * BAR_SPACING + [closingBarLine width] +
			self.closingRehearsalMarksSpacing - 0;
		
	}
	return calculatedWidth;
	
}

- (float) widthIncludingAnnotation {
	if (needsRecalculateWidthIncludingAnnotation) {
		[self updateLayout];
		needsRecalculateWidthIncludingAnnotation = NO;
		
		calculatedWidthIncludingAnnotation = [self signaturesWidth] + [openingBarLine width] +
			self.innerWidthIncludingAnnotation + 2 * BAR_SPACING + [closingBarLine width] +
			self.closingRehearsalMarksSpacing - 0;
		
	}
	return calculatedWidthIncludingAnnotation;
	
}

- (float) height {
	return 56.f + 0;
	
}

- (void) expandToWidth: (float) width spaceToDistribute: (float) space {
	
	closingBarLine.scaledPosition = CGPointMake (
		width, closingBarLine.scaledPosition.y
		
	);
	if (openingBarLine.barMark && !openingBarLine.barMark.hidden) {
		if ([((OpeningBarLine*)	openingBarLine.modelObject).barMark isEqualToString: BAR_LINE_BAR_MARK_TWO_BAR_SIMILE]) {
			openingBarLine.barMark.scaledPosition = CGPointMake (
				closingBarLine.scaledPosition.x - openingBarLine.barMark.width / 2 - 9 -
					openingBarLine.scaledPosition.x,
				openingBarLine.barMark.scaledPosition.y
				
			);
			
		} else {
			openingBarLine.barMark.scaledPosition = CGPointMake (
				(closingBarLine.scaledPosition.x - openingBarLine.scaledPosition.x) / 2 - openingBarLine.barMark.width / 2 - 3 -
					openingBarLine.scaledPosition.x * 0,
				openingBarLine.barMark.scaledPosition.y
				
			);
			
		}
		
	}
	
	if (lastExpadedWidth != width) {
		lastExpadedWidth = width;
		needsExpandChords = YES;
		
	}
	
	if (needsExpandChords) {
		int numChords = (int) [chords count];
		// space = width - self.innerWidth;
		
		float barInset = MIN (
			4, space / (numChords + 1)
			
		);
		space -= barInset * 2;
		float cursor = barInset;
		
		if (numChords) {
			float spaceBetweenElements = numChords > 1 ? space / (numChords - 1) : 0;
			int numChords = (int) [chords count];
			for (int i = 0; i < numChords; i++) {
				ChordLayer* chord = [chords objectAtIndex: i];
				chord.scaledPosition = CGPointMake (
					chord -> barOffset + cursor,
					CHORD_Y_OFFSET
					
				);
				CGPoint shadowPosition = chord -> shadowLayer.scaledPosition;
				chord -> shadowLayer.scaledPosition = CGPointMake (
					chord.width + 0.f + (i < numChords - 1 ? spaceBetweenElements / 2 : 1),
					// chord.width - 10 + 1 + spaceBetweenElements / 2,
					shadowPosition.y
					
				);
				cursor += spaceBetweenElements;
				
			}
			
		}
		needsExpandChords = NO;
		
	}
	
	const float paddingTop = -10;
	localBounds = CGRectMake (
		0, paddingTop,
		width, self.height - paddingTop
		
	);
	[self setNeedsRecalcConcatenatedBounds: YES];
	
}

//

- (void) dealloc {
	
	[openingBarLine release];
	[closingBarLine release];
	
	[chords release];
	
	[super dealloc];
	
}

//

+ (float) offsetForBetweenLeft: (BarLayer*) leftBar right: (BarLayer*) rightBar {
	return [BarLineLayer offsetForBetweenLeft: leftBar -> closingBarLine right: rightBar -> openingBarLine];
	
}


@end
